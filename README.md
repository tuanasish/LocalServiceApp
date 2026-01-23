# 🛒 Chợ Quê - Food Delivery for Rural Vietnam

**Chợ Quê** is a high-performance food delivery application specifically designed for rural Vietnam. It prioritizes simplicity, low data usage, and works efficiently even in areas with weak internet connectivity.

> **Status**: MVP Development (Week 4)  
> **Target**: 1 District (Initial Pilot)  
> **Stack**: Flutter + Riverpod + Supabase

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.10.1+
- [Dart](https://dart.dev/get-started) 3.x
- Android Studio or VS Code with Flutter extension

### Installation
```bash
# Clone the repository
git clone https://github.com/tuanasish/choque.git
cd choque/choque

# Install dependencies
flutter pub get

# Run the application
flutter run
```

---

## ✨ Features by Role

### 👤 Customer App
- **Product Discovery**: Fast menu browsing with low-res image support.
- **Smart Checkout**: Delivery time validation (Same-day/Next-day).
- **Order Tracking**: Real-time status updates and delivery timeline.
- **Address Management**: Save multiple shipping locations with GPS tags.

### 🛵 Driver App
- **Order Management**: Accept/Reject incoming delivery requests.
- **Navigation**: Integration with VietMap/Google Maps (Planned).
- **Status Updates**: Simple flow (Pick up -> In Transit -> Delivered).

### 🏪 Merchant & Admin
- **Menu Management**: Update items, prices, and availability in real-time.
- **Dashboard**: Overview of orders, revenue, and store performance.
- **Excel Import**: Bulk menu import via CSV/Excel (See [Excel Guide](docs/09-EXCEL-IMPORT-GUIDE.md)).

---

## 🏗️ Architecture & Tech Stack

| Layer | Technology | Status |
|-------|------------|--------|
| **UI Framework** | [Flutter](https://flutter.dev/) | 🟢 Active |
| **State Management** | [Riverpod 3](https://riverpod.dev/) | 🟢 Active |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) | 🟢 Active |
| **Design System** | Custom (lib/ui/design_system.dart) | 🟢 Active |
| **Backend** | [Supabase](https://supabase.com/) | 🟡 Implementation Phase |
| **Pusher** | [Pusher Channels](https://pusher.com/) | 🟢 Active (Real-time orders) |

### Directory Structure
```text
choque/
├── lib/
│   ├── main.dart             # App entry point
│   ├── routing/              # Navigation system
│   ├── ui/                   # Global Design System & reusable widgets
│   ├── screens/              # Feature-based screen modules
│   │   ├── home/             # Customer discovery
│   │   ├── order/            # Checkout & delivery tracking
│   │   ├── driver/           # Delivery partner module
│   │   └── merchant/         # Store owner dashboard
│   └── providers/            # Riverpod state providers
└── docs/                     # Project knowledge base (SQL, Briefs, Guides)
```

---

## 📋 Documentation Reference

| Document | Purpose |
|----------|---------|
| [Project Brief](docs/01-BRIEF-LOCKED.md) | Business requirements and MVP scope. |
| [DB Schema](docs/02-SCHEMA.sql) | Supabase/PostgreSQL table structures. |
| [Conversion Checklist](docs/14-STITCH-SCREENS.md) | Tracking UI implementation progress. |
| [Import Guide](docs/09-EXCEL-IMPORT-GUIDE.md) | Instructions for bulk data import. |
| [Roadmap](docs/06-ROADMAP-4-WEEKS.md) | Developmental timeline and milestones. |

---

## 🎨 Design System

We follow a strict "Primitive Colors & Soft Shadows" design approach located in `lib/ui/design_system.dart`:
- **Primary Color**: `#1E7F43` (Rustic Green)
- **Border Radius**: 12px (Small), 16px (Medium), 24px (Large)
- **Typography**: Inter (via Google Fonts)

---

## 📝 License
Private Project - © 2026 Chợ Quê Team. All rights reserved.

---
*Built with ❤️ for rural Vietnam using AI-assisted development.*
