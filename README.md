# Ask Us Marketplace

A comprehensive mobile marketplace platform that connects buyers and sellers with integrated payment processing, real-time chat, and service management.

## 📱 Overview

Ask Us is a feature-rich marketplace application built with Flutter for mobile and PHP/MySQL for backend. It provides a seamless experience for vendors to register, list products/services, and manage orders while customers browse, enquire, and make purchases.

## ✨ Key Features

### For Customers
- 🔍 Browse products and services
- 💬 Real-time chat with vendors
- ❓ Send enquiries and get responses
- 🛒 Add products to cart
- 💳 Secure payment processing via Razorpay
- 📍 Location-based search
- ⭐ Rate and review vendors
- 🔔 Push notifications

### For Vendors
- 📝 Vendor registration with payment verification
- 📦 Manage products and services
- 📊 Order management dashboard
- 💬 Customer communication via chat
- 📈 Analytics and performance metrics
- 📱 Mobile-first vendor interface
- 🏪 Store customization options
- 💰 Payment settlement tracking

### Admin Features
- 👥 Vendor approval and management
- 📋 Order monitoring
- 🎯 Category management
- 📊 Platform analytics
- 🚨 Report management

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.0+
- **State Management**: Provider/GetX
- **HTTP Client**: Dio
- **Local Storage**: SQLite, Shared Preferences
- **Payment**: Razorpay Flutter SDK
- **Real-time**: WebSocket

### Backend
- **Language**: PHP 7.4+
- **Framework**: Pure PHP (Custom REST API)
- **Database**: MySQL 5.7+
- **Authentication**: JWT (JSON Web Tokens)
- **Payment Gateway**: Razorpay API
- **API Style**: RESTful

### Infrastructure
- **Server**: Nginx
- **Hosting**: Linux-based shared/VPS hosting
- **Database**: MySQL with InnoDB engine
- **SSL**: HTTPS enabled

## 📋 Prerequisites

### Development
- Flutter SDK 3.0+
- Android SDK (for Android development)
- Xcode (for iOS development)
- PHP 7.4+ with PDO extension
- MySQL 5.7+
- Composer (for PHP dependency management)

### Accounts & Keys
- Razorpay account with API keys
- Email service for notifications
- Cloud storage (optional, for image hosting)

## 🚀 Getting Started

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/codemuji/askus-1.0.git
   cd askus-main
   ```

2. **Configure the server**
   - Upload PHP files to your web server (`/app/askus/api/`)
   - Update `config.php` with your database credentials:
     ```php
     define('DB_HOST', 'localhost');
     define('DB_USER', 'your_db_user');
     define('DB_PASS', 'your_db_password');
     define('DB_NAME', 'askus');
     ```

3. **Database setup**
   - Import the database schema
   - Run migrations to create tables
   - Verify table structure with `test-payment-update.php`

4. **Configure Razorpay**
   - Add your Razorpay API keys to `config.php`:
     ```php
     define('RAZORPAY_KEY_ID', 'your_razorpay_key');
     define('RAZORPAY_KEY_SECRET', 'your_razorpay_secret');
     ```

### Frontend Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API endpoint**
   - Update API base URL in the app configuration
   - Default: `https://indiawebdesigns.in/app/askus/api/`

3. **Build and run**
   ```bash
   # iOS
   flutter run -t lib/main.dart --release
   
   # Android
   flutter build apk --release
   ```

## 📚 API Documentation

### Authentication
All protected endpoints require JWT token in header:
```
Authorization: Bearer <your_jwt_token>
```

### Key Endpoints

**Payment Management**
- `POST /payments/create.php` - Create payment order
- `POST /payments/verify.php` - Verify payment signature

**Vendor Management**
- `POST /auth/create-vendor-after-payment.php` - Create vendor after payment
- `POST /vendor/register.php` - Vendor registration
- `GET /vendor/profile.php` - Get vendor profile

**Products & Services**
- `GET /products/list.php` - List products
- `POST /products/create.php` - Create product
- `GET /services/list.php` - List services

**Chat & Enquiries**
- `POST /chat/send.php` - Send message
- `GET /chat/messages.php` - Get messages
- `POST /enquiries/create.php` - Create enquiry

## 🔐 Security

- ✅ JWT-based authentication
- ✅ Password hashing with bcrypt
- ✅ HTTPS/SSL encryption
- ✅ CORS protection
- ✅ Input validation and sanitization
- ✅ SQL prepared statements to prevent SQL injection
- ✅ Razorpay signature verification

## 📦 Database Schema

Key tables:
- `users` - Customer accounts
- `vendors` - Vendor accounts
- `products` - Product listings
- `services` - Service listings
- `payments` - Payment records
- `orders` - Customer orders
- `chat_messages` - Chat communication
- `enquiries` - Customer enquiries
- `reviews` - Ratings and reviews

## 🚨 Troubleshooting

### Payment Issues
- **401 Unauthorized**: Check JWT token validity
- **500 Payment Error**: Verify Razorpay keys in config.php
- **Data truncation**: Ensure database enum values match (status: 'success', not 'completed')

### Vendor Registration
- Ensure vendor registration payment amount matches database expectations
- Check that email validation is working properly
- Verify payment verification endpoint is returning 'success' status

### Database Errors
- Run diagnostic: `test-payment-update.php`
- Check table structure matches expected schema
- Verify character encoding is UTF-8MB4

## 📝 Deployment

### Production Checklist
- [ ] Set strong database passwords
- [ ] Configure environment-specific settings
- [ ] Enable HTTPS/SSL
- [ ] Set appropriate CORS headers
- [ ] Configure email notifications
- [ ] Test payment flow end-to-end
- [ ] Set up error logging
- [ ] Configure backup strategy
- [ ] Test with real Razorpay credentials

### Environment Variables
Create `.env` or update config.php:
```php
DB_HOST=production_host
DB_USER=production_user
DB_PASS=secure_password
RAZORPAY_KEY_ID=rzp_live_xxx
RAZORPAY_KEY_SECRET=xxx
JWT_SECRET=your_secret_key
```

## 📊 Project Structure

```
askus-main/
├── lib/                          # Flutter app source
│   ├── main.dart
│   ├── core/                     # Core utilities
│   ├── features/                 # Feature modules
│   │   ├── payment/
│   │   ├── auth/
│   │   ├── vendor/
│   │   ├── products/
│   │   └── chat/
│   └── services/                 # API services
├── android/                      # Android configuration
├── ios/                          # iOS configuration
├── payments-create-fixed.php     # Payment creation API
├── payments-verify-fixed-2.php   # Payment verification API
├── api-auth-create-vendor-after-payment.php
├── config.php                    # Backend configuration
└── README.md
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 👥 Team

**Developer**: CodeMuji  
**Repository**: [askus-1.0](https://github.com/codemuji/askus-1.0)

## 📞 Support

For issues and questions:
- GitHub Issues: [Report a bug](https://github.com/codemuji/askus-1.0/issues)
- Email: support@askusmarketplace.com
- Documentation: Check the DEPLOYMENT_INSTRUCTIONS.md and DEBUGGING_GUIDE.md

## 🎯 Roadmap

- [ ] Push notifications
- [ ] Video chat support
- [ ] Advanced analytics
- [ ] Multi-language support
- [ ] AI-powered recommendations
- [ ] Subscription plans
- [ ] Marketplace commission tracking
- [ ] Advanced reporting tools

## ✅ Recent Fixes & Updates

### Payment System (v1.0.1)
- ✅ Fixed vendor registration payment flow
- ✅ Corrected payment status ENUM values ('success' instead of 'completed')
- ✅ Implemented payment verification with signature validation
- ✅ Added proper error handling and logging
- ✅ Vendor creation after payment verification

### Vendor Registration (v1.0.1)
- ✅ Allow unauthenticated payment creation for new vendors
- ✅ Validate vendor account creation
- ✅ Proper database constraint handling
- ✅ Enhanced error messages

## 📈 Version History

**v1.1.0** (April 2026)
- Marketplace final polish and release
- Updated UI versioning
- Optimized performance and assets
- Final feature integration completed

**v1.0.1** (Jan 2026)
- Payment and vendor registration fixes
- Enhanced error logging
- Database schema validation

**v1.0.0** (Initial Release)
- Core marketplace features
- Payment integration
- Chat system
- Vendor management

---

**Last Updated**: April 02, 2026  
**Status**: Release Candidate ✅
