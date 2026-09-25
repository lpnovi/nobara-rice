# Nobara Enhanced Splash

`nobara-enhanced.splash` is a minimal KSplashQML splash screen: a near-black (`#050408`)
background with the gradient Nobara logo centred at 220 px.

```
nobara-enhanced.splash/
├── metadata.json
└── contents/splash/
    ├── Splash.qml
    └── images/logo.png      same image as assets/nobara-logo.png
```

Install: `cp -r nobara-enhanced.splash ~/.local/share/plasma/look-and-feel/`, then pick it in
System Settings → Colors & Themes → Splash Screen, or run
`kwriteconfig6 --file ksplashrc --group KSplash --key Theme nobara-enhanced.splash`.
