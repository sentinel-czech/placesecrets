# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HeroDots is a POI (Point of Interest) AudioGuide & Travel Log application consisting of two parts:

1. **Mobile App** (`specification-prompts.md`) — Flutter/Dart app for Android & iOS
2. **Admin Panel** (`spec-prompts-admin.md`) — Vite + React 18 + TypeScript + Tailwind CSS SPA

Both share the same **Supabase** backend (PostgreSQL, Auth, Storage, Edge Functions).

## Specification Language

All specifications are written in **Czech**. When implementing features, follow the Czech-language specs but write code (variable names, comments, commit messages) in English.

## Architecture

### Mobile App (Flutter)
- **Package:** `cz.tuma.herodots`
- **State management:** Riverpod (with code generation via `riverpod_generator`)
- **Navigation:** GoRouter
- **Local DB:** Drift (SQLite)
- **Maps:** flutter_map (OpenStreetMap-based, not Google Maps)
- **Audio:** just_audio + flutter_tts
- **Payments:** Google Pay / Apple Pay (`pay` package) + Revolut deep-link
- **Geolocation:** geolocator + flutter_background_geolocation
- **Min Android SDK:** 23 | **Min iOS:** 14.0 | **Target SDK:** 34
- Implement sections in order: 1 through 17

### Admin Panel (React)
- **Stack:** Vite + React 18 + TypeScript + Tailwind CSS
- **Deploy target:** Netlify/Vercel static build at `admin.herodots.app`
- **Supabase access:** Uses `service_role` key directly (behind auth guard)
- No SSR, no Next.js, no Express — pure SPA

### Supabase Backend (shared)
- **Auth:** Supabase Auth (anonymous + email for mobile; `admin_users` table for admin)
- **Key tables:** `cities`, `pois`, `users`, `payments`, `payment_receipts`, `user_access`
- **Storage buckets:** `poi-photos`, `audio-guides`, `payment-receipts`
- **Edge Functions:** `confirm-payment`, `generate-receipt`, `delete-user-data`, `migrate-anonymous-data`
- Row Level Security (RLS) enabled on all tables

## Common Commands

### Flutter Mobile App
```bash
flutter create --org cz.tuma --project-name herodots --platforms android,ios herodots
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # generate Drift, Riverpod, Freezed, JSON code
flutter run
flutter test
flutter build apk --release
flutter build ios --release
```

### Admin Panel (React + Vite)
```bash
npm install        # or pnpm install
npm run dev        # Vite dev server
npm run build      # production build
npm run preview    # preview production build
```

### Supabase
```bash
supabase start                    # local dev
supabase db push                  # apply migrations
supabase functions serve          # local Edge Functions
supabase functions deploy <name>  # deploy single Edge Function
```

## Key Design Decisions

- **Offline-first:** Mobile app uses Drift for local caching; sync with Supabase when online
- **Anonymous users:** App supports anonymous Supabase auth; data migrates on account creation
- **Payment receipts:** EU consumer law compliance — PDF receipts generated via Edge Function, stored in Supabase Storage
- **Geofencing:** Background geolocation triggers audio guides when user enters POI radius
- **No Google Maps:** Uses OpenStreetMap via flutter_map to avoid licensing costs
