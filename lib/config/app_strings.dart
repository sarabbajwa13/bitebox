/// Central place for all user-facing text/labels.
///
/// Kal multi-language chahiye to isi class ko localize kar sakte ho.
class AppStrings {
  AppStrings._();

  // Dashboard / listing
  static const String nearbyStores = 'Stores near you';
  static const String nearbyStoresSubtitle =
      'Freshly made snacks around your location';
  static const String noStoresTitle = 'No stores in your area yet';
  static const String noStoresSubtitle =
      'We are expanding fast — check back soon!';
  static const String searchHint = 'Search stores or dishes';

  // Store detail
  static const String menuTitle = 'Menu';
  static const String closedLabel = 'Closed';
  static const String openLabel = 'Open';

  // Item / variant
  static const String chooseVariant = 'Choose a variant';
  static const String addToCart = 'Add';
  static const String added = 'Added';

  // Cart / order
  static const String cartTitle = 'Your order';
  static const String emptyCart = 'Your cart is empty';
  static const String emptyCartSubtitle = 'Add some tasty items to get started';
  static const String subtotal = 'Subtotal';
  static const String placeOrder = 'Place order';
  static const String orderPlacedTitle = 'Order placed!';
  static const String orderPlacedSubtitle =
      'We have received your order and will start preparing it right away.';
  static const String continueShopping = 'Back to stores';

  // Order form
  static const String yourName = 'Your name';
  static const String phoneNumber = 'Phone number';
  static const String nameRequired = 'Please enter your name';
  static const String phoneRequired = 'Please enter your phone number';
  static const String phoneInvalid = 'Enter a valid 10-digit number';

  // Auth (phone OTP)
  static const String loginTitle = 'Login to continue';
  static const String loginSubtitle =
      'Enter your mobile number to receive an OTP';
  static const String sendOtp = 'Send OTP';
  static const String otpSentTo = 'Enter the OTP sent to';
  static const String otpLabel = 'OTP';
  static const String verifyLogin = 'Verify & continue';
  static const String changeNumber = 'Change number';
  static const String resendOtp = 'Resend OTP';
  static const String logout = 'Logout';

  // Orders / history / tracking
  static const String myOrders = 'My orders';
  static const String orderHistoryTitle = 'Your orders';
  static const String noOrdersTitle = 'No orders yet';
  static const String noOrdersSubtitle =
      'Your placed orders will appear here so you can track them';
  static const String trackOrder = 'Track order';
  static const String orderStatusTitle = 'Order status';
  static const String orderRejectedNote =
      'This order was not accepted. Any amount, if paid, will be refunded.';
  static const String demoAgentTitle = 'Demo: agent action';
  static const String demoAgentSubtitle =
      'Agent app abhi nahi bana — yahan se accept/reject simulate karke status dekho';
  static const String accept = 'Accept';
  static const String reject = 'Reject';

  // Generic
  static const String km = 'km away';
  static const String items = 'items';
  static const String vegOnly = 'Veg';
}
