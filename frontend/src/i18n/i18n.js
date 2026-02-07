import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Import language files

// English translations
import enCommon from './locales/en/common.json';
import enLanguage from './locales/en/language.json';
import enNavigation from './locales/en/navigation.json';
import enLandingPage from './locales/en/landingPage.json';
import enChapterView from './locales/en/chapterView.json';
import enAdminView from './locales/en/adminView.json';
import enAbout from './locales/en/about.json';
import enDashboard from './locales/en/dashboard.json';
import enAuth from './locales/en/auth.json';
import enSettings from './locales/en/settings.json';
import enApp from './locales/en/app.json';
import enAdmin from './locales/en/admin.json';
import enFooter from './locales/en/footer.json';
import enChatTool from './locales/en/chatTool.json';
import enGeoGebraPlotter from './locales/en/geoGebraPlotter.json';
import enNotesTool from './locales/en/notesTool.json';
import enCourseView from './locales/en/courseView.json';
import enCreateCourse from './locales/en/createCourse.json';
import enPricing from './locales/en/pricing.json';
import enImpressum from './locales/en/impressum.json';
import enPrivacy from './locales/en/privacy.json';
import enToolbarContainer from './locales/en/toolbarContainer.json';
import enStatisticsPage from './locales/en/statisticsPage.json';

// Configure i18n with default namespace
const i18nInstance = i18n.createInstance();

i18nInstance
  .use(initReactI18next)
  .init({
    // Configure namespaces
    defaultNS: 'common',
    ns: ['common', 'pricing'],
    defaultNS: 'common',
    lng: 'en', // Lock to English
    fallbackLng: 'en',
    
    // Enable debug in development
    debug: process.env.NODE_ENV === 'development',
    
    // Use dot notation for nested keys
    keySeparator: '.',
    nsSeparator: ':',
    resources: {
      en: {
        // Common translations
        common: enCommon,
        language: enLanguage,
        navigation: enNavigation,
        landingPage: enLandingPage,
        chapterView: enChapterView,
        adminView: enAdminView,
        about: enAbout,
        dashboard: enDashboard,
        auth: enAuth,
        settings: enSettings,
        app: enApp,
        admin: enAdmin,
        footer: enFooter,
        chatTool: enChatTool,
        geoGebraPlotter: enGeoGebraPlotter,
        notesTool: enNotesTool,
        courseView: enCourseView,
        createCourse: enCreateCourse,
        pricing: enPricing,
        impressum: enImpressum,
        privacy: enPrivacy,
        toolbarContainer: enToolbarContainer,
        statisticsPage: enStatisticsPage,
      },
    },
    fallbackLng: 'en',
    //debug: process.env.NODE_ENV === 'development',
    
    interpolation: {
      escapeValue: false, // React already safes from XSS
    },
  });

// Export the configured instance
export default i18nInstance;
