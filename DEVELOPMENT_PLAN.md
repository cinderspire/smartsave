# SmartSave - Development Plan

## Current Status: 30-35% Complete

## Completed ✅
- [x] Project setup
- [x] Firebase configuration
- [x] Riverpod setup
- [x] Secure storage
- [x] Basic theme

## Phase 1: Authentication

### 1.1 User Auth
- [ ] Email/password login
- [ ] Email/password signup
- [ ] Password reset
- [ ] Google sign-in
- [ ] Session management

### 1.2 Profile
- [ ] User profile setup
- [ ] Profile editing
- [ ] Account settings

## Phase 2: Savings Features

### 2.1 Round-Ups
- [ ] Link payment method (mock)
- [ ] Transaction monitoring
- [ ] Round-up calculation
- [ ] Automatic savings

### 2.2 Auto-Save
- [ ] Schedule setup
- [ ] Daily/weekly/monthly
- [ ] Amount configuration
- [ ] Toggle on/off

### 2.3 Savings Goals
- [ ] Create goal
- [ ] Set target amount
- [ ] Set deadline
- [ ] Track progress
- [ ] Goal completion

## Phase 3: Dashboard

### 3.1 Overview
- [ ] Total savings display
- [ ] Goals progress
- [ ] Recent activity
- [ ] Quick actions

### 3.2 Analytics
- [ ] Savings chart
- [ ] Monthly comparison
- [ ] Goal projections

## Phase 4: Investments (Mock)

### 4.1 Portfolio
- [ ] Mock investment options
- [ ] Portfolio display
- [ ] Performance tracking

## Data Models

```dart
class User {
  String id;
  String email;
  String name;
  double totalSavings;
  List<SavingsGoal> goals;
}

class SavingsGoal {
  String id;
  String name;
  double targetAmount;
  double currentAmount;
  DateTime deadline;
}

class Transaction {
  String id;
  double amount;
  String type; // round-up, auto-save, manual
  DateTime date;
}
```

## Estimated Completion
**Total: 4-5 weeks**
