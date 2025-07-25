# Food Delivery App

A **Flutter + Firebase-based Food Delivery Application** built as part of internship submission.  
This app allows users to explore restaurants, browse food items, manage their cart, place orders, and view order history.

---

## ✨ Features Implemented

- **Firebase Authentication (Email/Password)**
  - Login & Signup with validation
  - Persistent session (token saved after restart)
- **Firestore Integration**
  - Restaurants & food items fetched from Firestore
- **Cart Management**
  - Add, remove items, update quantity, auto total calculation
- **Order Flow**
  - Place order → Order success page → Order history
- **Profile Page**
  - Display user info (FirebaseAuth)
  - Update username
  - Logout functionality
- **State Management**
  - Implemented using `Provider`
- **Local Storage**
  - Used `SharedPreferences` for lightweight storage
- **UI**
  - Clean, Material Design UI with snackbars for feedback
- **Validation**
  - Strong password rules (1 uppercase, 1 number, 1 special char, min 8 chars)
  - Error handling for login, signup, and profile update
- **Extra**
  - User-Friendly Messages : No raw Firebase exception messages shown; all authentication and profile errors are custom-handled and user-friendly.
  - Order History with Item Breakdown : Orders display expandable sections with detailed item names, quantity, and prices in profile section.
  - Cancel Pending Orders : Users can cancel orders that are still in the “Ordered” status, directly from the order history screen.

---

## 🔧 Firebase Setup

The project already contains a **working Firebase setup** (`google-services.json` included),  
so you don’t need to configure Firebase separately. **Just clone and run**.

---

## 🚀 Running the App

1. **Clone the repository**
   ```bash
   git clone https://github.com/Pratiksha575-dev/food_delivery_app.git
   cd food_delivery_app
2.Get dependencies
  ```bash
   flutter pub get
```
3.Run on emulator or device (Recommended emulator: Pixel 8 Pro API 35)
```bash
flutter run
```
👩‍💻 Developed By
Pratiksha Zodge.
