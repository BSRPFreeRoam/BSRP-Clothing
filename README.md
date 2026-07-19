# 👕 BSRP Clothing

A modern and customizable clothing system built exclusively for the **BSRP Framework**.

BSRP Clothing provides players with a complete character customization experience, allowing them to change outfits, manage their appearance, and personalize their characters through a smooth and immersive interface.

Designed with performance, flexibility, and future expansion in mind, BSRP Clothing integrates seamlessly with the BSRP ecosystem to provide a modern roleplay experience.

---

## 📌 Features

✅ Fully integrated with **BSRP Framework**
✅ Character clothing customization
✅ Outfit management system
✅ Clothing stores
✅ Appearance customization
✅ Modern UI experience
✅ Optimized performance
✅ Lightweight resource usage
✅ Easy configuration
✅ Designed for future BSRP expansions

---

## 🔗 Requirements

This resource requires:

* **BSRP Framework**

  * Repository: https://github.com/BSRPFreeRoam/BSRP-FrameWork

* FiveM Server

* GTA V

* OneSync Recommended

---

## 📥 Installation

### 1. Download

Download or clone the resource into your server resources folder:

```bash
cd resources
git clone https://github.com/BSRPFreeRoam/BSRP-Clothing.git
```

---

### 2. Add to `server.cfg`

Add the following:

```cfg
ensure BSRP-Clothing
```

Make sure the **BSRP Framework** starts before this resource:

```cfg
ensure BSRP-FrameWork
ensure BSRP-Clothing
```

---

## ⚙️ Configuration

All settings can be found inside:

```text
config.lua
```

Example:

```lua
Config = {}

Config.Enabled = true

Config.SaveOutfits = true

Config.EnableStores = true

Config.EnableBarber = true
```

---

## 🎨 Customization

You can customize:

* Clothing locations
* Outfit settings
* UI appearance
* Character options
* Store locations
* Available clothing features
* Notifications

Modify the configuration files to match your server's branding and roleplay style.

---

## 🖥️ Framework Integration

BSRP Clothing is designed specifically for:

* BSRP Framework
* BSRP Character Systems
* BSRP Garage
* BSRP Map HUD
* Future BSRP resources

The resource integrates directly with the BSRP ecosystem to provide a consistent, modern, and immersive character customization experience.
