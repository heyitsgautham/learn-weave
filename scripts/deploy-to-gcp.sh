#!/bin/bash
# =============================================================================
# LearnWeave GCP Deployment Script
# =============================================================================
# This script automates the deployment of LearnWeave to Google Cloud Platform
# Review GCP_DEPLOYMENT_COMPLEXITIES.md before running this script
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
REGION="${GOOGLE_CLOUD_LOCATION:-us-central1}"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}${1}${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "gcloud CLI found"
    
    # Check if logged in
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        print_error "Not logged in to gcloud. Run: gcloud auth login"
        exit 1
    fi
    print_success "gcloud authenticated"
    
    # Check if project is set
    if [ -z "$PROJECT_ID" ]; then
        print_error "GOOGLE_CLOUD_PROJECT is not set"
        exit 1
    fi
    print_success "Project ID: $PROJECT_ID"
    print_success "Region: $REGION"
}

# Enable required APIs
enable_apis() {
    print_section "Enabling Required APIs"
    
    APIS=(
        "run.googleapis.com"
        "cloudbuild.googleapis.com"
        "artifactregistry.googleapis.com"
        "firestore.googleapis.com"
        "storage.googleapis.com"
        "secretmanager.googleapis.com"
        "aiplatform.googleapis.com"
        "cloudscheduler.googleapis.com"
        "logging.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        print_info "Enabling $api..."
        gcloud services enable $api --project=$PROJECT_ID
    done
    
    print_success "All APIs enabled"
}

# Create Artifact Registry repository
create_artifact_registry() {
    print_section "Setting Up Artifact Registry"
    
    # Check if repository exists
    if gcloud artifacts repositories describe learnweave-repo --location=$REGION &> /dev/null; then
        print_warning "Repository 'learnweave-repo' already exists"
    else
        print_info "Creating Artifact Registry repository..."
        gcloud artifacts repositories create learnweave-repo \
            --repository-format=docker \
            --location=$REGION \
            --description="LearnWeave container images" \
            --project=$PROJECT_ID
        print_success "Artifact Registry created"
    fi
    
    # Configure Docker auth
    print_info "Configuring Docker authentication..."
    gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
    print_success "Docker authentication configured"
}

# Set up Firestore
setup_firestore() {
    print_section "Setting Up Firestore"
    
    # Check if Firestore is already initialized
    if gcloud firestore databases list --project=$PROJECT_ID 2>/dev/null | grep -q "(default)"; then
        print_warning "Firestore already initialized"
    else
        print_info "Creating Firestore database..."
        gcloud firestore databases create \
            --location=$REGION \
            --type=firestore-native \
            --project=$PROJECT_ID
        print_success "Firestore database created"
    fi
}

# Create Cloud Storage buckets
create_storage_buckets() {
    print_section "Creating Cloud Storage Buckets"
    
    BUCKETS=(
        "${PROJECT_ID}-generated-images"
        "${PROJECT_ID}-user-uploads"
        "${PROJECT_ID}-anki-exports"
        "${PROJECT_ID}-chromadb-storage"
    )
    
    for bucket in "${BUCKETS[@]}"; do
        if gsutil ls -b gs://${bucket} &> /dev/null; then
            print_warning "Bucket gs://${bucket} already exists"
        else
            print_info "Creating bucket gs://${bucket}..."
            gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://${bucket}
            print_success "Created gs://${bucket}"
        fi
    done
    
    # Make generated-images bucket publicly readable
    print_info "Setting public access for generated-images bucket..."
    gsutil iam ch allUsers:objectViewer gs://${PROJECT_ID}-generated-images
    print_success "Public access configured"
}

# Create service account
create_service_account() {
    print_section "Creating Service Account"
    
    SA_NAME="learnweave-backend"
    SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    # Check if service account exists
    if gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &> /dev/null; then
        print_warning "Service account $SA_EMAIL already exists"
    else
        print_info "Creating service account..."
        gcloud iam service-accounts create $SA_NAME \
            --display-name="LearnWeave Backend Service Account" \
            --project=$PROJECT_ID
        print_success "Service account created"
    fi
    
    # Grant necessary permissions
    print_info "Granting IAM permissions..."
    
    ROLES=(
        "roles/datastore.user"
        "roles/storage.objectAdmin"
        "roles/aiplatform.user"
        "roles/secretmanager.secretAccessor"
        "roles/logging.logWriter"
    )
    
    for role in "${ROLES[@]}"; do
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:${SA_EMAIL}" \
            --role="$role" \
            --condition=None \
            --quiet
    done
    
    print_success "IAM permissions granted"
}

# Set up Secret Manager
setup_secrets() {
    print_section "Setting Up Secret Manager"
    
    print_warning "You need to manually create secrets with actual values:"
    echo ""
    echo "  1. JWT_SECRET_KEY"
    echo "  2. SESSION_SECRET_KEY"
    echo "  3. GOOGLE_CLIENT_ID"
    echo "  4. GOOGLE_CLIENT_SECRET"
    echo ""
    echo "Example command:"
    echo "  echo -n 'your-secret-value' | gcloud secrets create jwt-secret-key --data-file=-"
    echo ""
    
    read -p "Press Enter after you've created the secrets, or Ctrl+C to abort..."
}

# Deploy ChromaDB
deploy_chromadb() {
    print_section "Deploying ChromaDB Service"
    
    SERVICE_NAME="learnweave-chromadb"
    IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/learnweave-repo/${SERVICE_NAME}"
    
    print_info "Using official ChromaDB image..."
    
    # Deploy ChromaDB
    print_info "Deploying ChromaDB to Cloud Run..."
    gcloud run deploy $SERVICE_NAME \
        --image chromadb/chroma:latest \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --memory 2Gi \
        --cpu 2 \
        --timeout 300 \
        --min-instances 1 \
        --max-instances 3 \
        --port 8000 \
        --execution-environment gen2 \
        --project=$PROJECT_ID
    
    # Get the URL
    CHROMA_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --project=$PROJECT_ID --format 'value(status.url)')
    print_success "ChromaDB deployed at: $CHROMA_URL"
    
    echo ""
    print_info "Update your backend .env with:"
    echo "CHROMA_DB_URL=$CHROMA_URL"
}

# Deploy Backend
deploy_backend() {
    print_section "Deploying Backend Service"
    
    SERVICE_NAME="learnweave-backend"
    IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/learnweave-repo/${SERVICE_NAME}"
    
    # Check if Dockerfile exists
    if [ ! -f "backend/Dockerfile.production" ]; then
        print_error "backend/Dockerfile.production not found"
        print_info "Please create the production Dockerfile first (see GCP_DEPLOYMENT_PLAN.md)"
        return 1
    fi
    
    print_info "Building backend container..."
    gcloud builds submit --tag $IMAGE_NAME \
        --project=$PROJECT_ID \
        --timeout=20m \
        backend/
    
    print_info "Deploying backend to Cloud Run..."
    gcloud run deploy $SERVICE_NAME \
        --image $IMAGE_NAME \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --memory 2Gi \
        --cpu 2 \
        --timeout 300 \
        --concurrency 80 \
        --min-instances 0 \
        --max-instances 10 \
        --set-env-vars "GOOGLE_GENAI_USE_VERTEXAI=true" \
        --set-env-vars "GOOGLE_CLOUD_PROJECT=${PROJECT_ID}" \
        --set-env-vars "GOOGLE_CLOUD_LOCATION=${REGION}" \
        --set-env-vars "USE_FIRESTORE=true" \
        --set-env-vars "USE_CLOUD_STORAGE=true" \
        --set-env-vars "GCS_BUCKET_IMAGES=${PROJECT_ID}-generated-images" \
        --set-env-vars "GCS_BUCKET_UPLOADS=${PROJECT_ID}-user-uploads" \
        --set-env-vars "GCS_BUCKET_EXPORTS=${PROJECT_ID}-anki-exports" \
        --set-secrets "SECRET_KEY=jwt-secret-key:latest" \
        --set-secrets "SESSION_SECRET_KEY=session-secret-key:latest" \
        --set-secrets "GOOGLE_CLIENT_ID=google-client-id:latest" \
        --set-secrets "GOOGLE_CLIENT_SECRET=google-client-secret:latest" \
        --service-account learnweave-backend@${PROJECT_ID}.iam.gserviceaccount.com \
        --project=$PROJECT_ID
    
    # Get the URL
    BACKEND_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --project=$PROJECT_ID --format 'value(status.url)')
    print_success "Backend deployed at: $BACKEND_URL"
    
    echo ""
    print_warning "IMPORTANT: Update your OAuth redirect URIs in Google Console:"
    echo "  $BACKEND_URL/api/auth/google/callback"
}

# Deploy Frontend
deploy_frontend() {
    print_section "Deploying Frontend Service"
    
    SERVICE_NAME="learnweave-frontend"
    IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/learnweave-repo/${SERVICE_NAME}"
    
    # Check if Dockerfile exists
    if [ ! -f "frontend/Dockerfile.production" ]; then
        print_error "frontend/Dockerfile.production not found"
        print_info "Please create the production Dockerfile first (see GCP_DEPLOYMENT_PLAN.md)"
        return 1
    fi
    
    # Get backend URL
    BACKEND_URL=$(gcloud run services describe learnweave-backend --region $REGION --project=$PROJECT_ID --format 'value(status.url)' 2>/dev/null || echo "")
    
    if [ -z "$BACKEND_URL" ]; then
        print_error "Backend service not found. Deploy backend first."
        return 1
    fi
    
    print_info "Building frontend container..."
    gcloud builds submit --tag $IMAGE_NAME \
        --project=$PROJECT_ID \
        --timeout=20m \
        --build-arg VITE_API_URL="${BACKEND_URL}/api" \
        frontend/
    
    print_info "Deploying frontend to Cloud Run..."
    gcloud run deploy $SERVICE_NAME \
        --image $IMAGE_NAME \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --memory 512Mi \
        --cpu 1 \
        --timeout 60 \
        --concurrency 80 \
        --min-instances 0 \
        --max-instances 5 \
        --project=$PROJECT_ID
    
    # Get the URL
    FRONTEND_URL=$(gcloud run services describe $SERVICE_NAME --region $REGION --project=$PROJECT_ID --format 'value(status.url)')
    print_success "Frontend deployed at: $FRONTEND_URL"
}

# Setup Cloud Scheduler
setup_scheduler() {
    print_section "Setting Up Cloud Scheduler"
    
    # Get backend URL
    BACKEND_URL=$(gcloud run services describe learnweave-backend --region $REGION --project=$PROJECT_ID --format 'value(status.url)' 2>/dev/null || echo "")
    
    if [ -z "$BACKEND_URL" ]; then
        print_warning "Backend service not found. Skipping scheduler setup."
        return 0
    fi
    
    # Create service account for Cloud Scheduler
    SA_NAME="cloud-scheduler"
    SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    
    if ! gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &> /dev/null; then
        gcloud iam service-accounts create $SA_NAME \
            --display-name="Cloud Scheduler Service Account" \
            --project=$PROJECT_ID
    fi
    
    # Grant invoker role
    gcloud run services add-iam-policy-binding learnweave-backend \
        --member="serviceAccount:${SA_EMAIL}" \
        --role="roles/run.invoker" \
        --region=$REGION \
        --project=$PROJECT_ID
    
    # Create scheduler job
    print_info "Creating Cloud Scheduler job for stuck courses update..."
    
    if gcloud scheduler jobs describe update-stuck-courses --location=$REGION --project=$PROJECT_ID &> /dev/null; then
        print_warning "Scheduler job already exists"
    else
        gcloud scheduler jobs create http update-stuck-courses \
            --location=$REGION \
            --schedule="0 * * * *" \
            --uri="${BACKEND_URL}/api/internal/update-stuck-courses" \
            --http-method=POST \
            --oidc-service-account-email=$SA_EMAIL \
            --oidc-token-audience="$BACKEND_URL" \
            --project=$PROJECT_ID
        
        print_success "Cloud Scheduler job created"
    fi
}

# Print deployment summary
print_summary() {
    print_section "Deployment Summary"
    
    echo ""
    print_info "Services deployed:"
    
    # ChromaDB
    CHROMA_URL=$(gcloud run services describe learnweave-chromadb --region $REGION --project=$PROJECT_ID --format 'value(status.url)' 2>/dev/null || echo "Not deployed")
    echo "  • ChromaDB: $CHROMA_URL"
    
    # Backend
    BACKEND_URL=$(gcloud run services describe learnweave-backend --region $REGION --project=$PROJECT_ID --format 'value(status.url)' 2>/dev/null || echo "Not deployed")
    echo "  • Backend:  $BACKEND_URL"
    
    # Frontend
    FRONTEND_URL=$(gcloud run services describe learnweave-frontend --region $REGION --project=$PROJECT_ID --format 'value(status.url)' 2>/dev/null || echo "Not deployed")
    echo "  • Frontend: $FRONTEND_URL"
    
    echo ""
    print_warning "Next Steps:"
    echo "  1. Update OAuth redirect URIs in Google Console"
    echo "  2. Test OAuth login flow"
    echo "  3. Run database migration: python3 scripts/migrate_to_firestore.py"
    echo "  4. Set up custom domain (optional)"
    echo "  5. Monitor logs: gcloud logging read 'resource.type=cloud_run_revision'"
    echo ""
}

# Main deployment flow
main() {
    print_section "LearnWeave GCP Deployment"
    echo "Project: $PROJECT_ID"
    echo "Region: $REGION"
    echo ""
    
    read -p "Continue with deployment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    check_prerequisites
    enable_apis
    create_artifact_registry
    setup_firestore
    create_storage_buckets
    create_service_account
    
    # Optional: setup secrets
    print_info "Skipping secret setup (do this manually first)"
    
    # Deploy services
    deploy_chromadb
    
    # Ask before deploying backend
    echo ""
    read -p "Deploy backend? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_backend
    fi
    
    # Ask before deploying frontend
    echo ""
    read -p "Deploy frontend? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_frontend
    fi
    
    # Setup scheduler
    setup_scheduler
    
    # Print summary
    print_summary
    
    print_success "Deployment complete!"
}

# Run main function
main
