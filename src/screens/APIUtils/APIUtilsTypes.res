type entityName =
  | CONNECTOR
  | ROUTING
  | MERCHANT_ACCOUNT
  | PAYMENT
  | REFUNDS
  | DISPUTES
  | PAYOUTS
  | ANALYTICS_PAYMENTS
  | ANALYTICS_DISPUTES
  | ANALYTICS_USER_JOURNEY
  | ANALYTICS_REFUNDS
  | ANALYTICS_AUTHENTICATION
  | SETTINGS
  | ONBOARDING
  | API_KEYS
  | ORDERS
  | DEFAULT_FALLBACK
  | CHANGE_PASSWORD
  | ANALYTICS_SYSTEM_METRICS
  | PAYMENT_LOGS
  | SDK_EVENT_LOGS
  | WEBHOOKS_EVENT_LOGS
  | CONNECTOR_EVENT_LOGS
  | GENERATE_SAMPLE_DATA
  | USERS
  | RECON
  | INTEGRATION_DETAILS
  | FRAUD_RISK_MANAGEMENT
  | USER_MANAGEMENT
  | TEST_LIVE_PAYMENT
  | THREE_DS
  | BUSINESS_PROFILE
  | VERIFY_APPLE_PAY
  | PAYMENT_REPORT
  | REFUND_REPORT
  | DISPUTE_REPORT
  | PAYPAL_ONBOARDING
  | SURCHARGE
  | CUSTOMERS
  | ACCEPT_DISPUTE
  | DISPUTES_ATTACH_EVIDENCE
  | PAYOUT_DEFAULT_FALLBACK
  | PAYOUT_ROUTING
  | GLOBAL_SEARCH
  | PAYMENT_METHOD_CONFIG

type userRoleTypes = USER_LIST | ROLE_LIST | ROLE_ID | NONE

type reconType = [#TOKEN | #REQUEST | #NONE]

type userType = [
  | #CONNECT_ACCOUNT
  | #SIGNUP
  | #SIGNINV2
  | #SIGNOUT
  | #FORGOT_PASSWORD
  | #RESET_PASSWORD
  | #RESET_PASSWORD_TOKEN_ONLY
  | #VERIFY_EMAIL_REQUEST
  | #VERIFY_EMAILV2
  | #ACCEPT_INVITE_FROM_EMAIL
  | #SET_METADATA
  | #SWITCH_MERCHANT
  | #PERMISSION_INFO
  | #MERCHANT_DATA
  | #MERCHANTS_SELECT
  | #USER_DATA
  | #USER_DELETE
  | #USER_UPDATE
  | #UPDATE_ROLE
  | #INVITE_MULTIPLE
  | #INVITE_MULTIPLE_TOKEN_ONLY
  | #RESEND_INVITE
  | #CREATE_MERCHANT
  | #ACCEPT_INVITE
  | #ACCEPT_INVITE_TOKEN_ONLY
  | #GET_PERMISSIONS
  | #CREATE_CUSTOM_ROLE
  | #SIGNUP_TOKEN_ONLY
  | #SIGNINV2_TOKEN_ONLY
  | #VERIFY_EMAILV2_TOKEN_ONLY
  | #ACCEPT_INVITE_FROM_EMAIL_TOKEN_ONLY
  | #FROM_EMAIL
  | #USER_INFO
  | #SIGNUPV2
  | #ROTATE_PASSWORD
  | #BEGIN_TOTP
  | #VERIFY_TOTP
  | #VERIFY_RECOVERY_CODE
  | #GENERATE_RECOVERY_CODES
  | #TERMINATE_TWO_FACTOR_AUTH
  | #CHECK_TWO_FACTOR_AUTH_STATUS
  | #RESET_TOTP
  | #GET_AUTH_LIST
  | #NONE
]
