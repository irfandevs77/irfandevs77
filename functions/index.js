const {BetaAnalyticsDataClient} = require('@google-analytics/data');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const {defineString} = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const analyticsPropertyId = defineString('GA4_PROPERTY_ID');

exports.getWebsiteVisits = onCall(
  {region: 'us-central1'},
  async (request) => {
    if (!request.auth || request.auth.token.admin !== true) {
      throw new HttpsError('permission-denied', 'Admin access is required.');
    }

    const propertyId = analyticsPropertyId.value();
    if (!propertyId) {
      throw new HttpsError(
        'failed-precondition',
        'Set GA4_PROPERTY_ID before requesting analytics.',
      );
    }

    try {
      const analytics = new BetaAnalyticsDataClient();
      const [report] = await analytics.runReport({
        property: `properties/${propertyId}`,
        dateRanges: [{startDate: '365daysAgo', endDate: 'today'}],
        metrics: [{name: 'sessions'}],
      });
      return {visits: Number(report.rows?.[0]?.metricValues?.[0]?.value ?? 0)};
    } catch (error) {
      logger.error('Could not read the GA4 visits report.', error);
      throw new HttpsError(
        'internal',
        'Could not retrieve website analytics. Check the GA4 property and service-account permissions.',
      );
    }
  },
);
