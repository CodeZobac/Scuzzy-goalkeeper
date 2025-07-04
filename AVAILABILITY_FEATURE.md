# Goalkeeper Availability Management Feature

## Overview
This feature allows goalkeepers to manage their availability schedules, enabling players to see when they can book games.

## Implementation

### 📁 File Structure
```
lib/src/features/availability/
├── data/
│   ├── models/
│   │   └── availability.dart          # Availability data model
│   └── repositories/
│       └── availability_repository.dart # Data access layer
├── presentation/
│   ├── controllers/
│   │   └── availability_controller.dart # State management
│   ├── screens/
│   │   └── availability_screen.dart    # Main UI screens
│   └── widgets/
│       ├── availability_widgets.dart   # Reusable UI components
│       └── availability_form_dialog.dart # Add/Edit form
└── availability.dart                   # Export file
```

### 🗄️ Database Schema
The availability data is stored in the `availabilities` table with the following structure:

```sql
CREATE TABLE public.availabilities (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    goalkeeper_id uuid REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    day date NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

### 🔐 Security Features
- **Row Level Security (RLS)**: Enabled to ensure data privacy
- **Access Policies**:
  - All users can view availabilities (for booking purposes)
  - Only goalkeepers can manage their own availabilities
  - Prevents unauthorized access and modifications

### ⚡ Key Features

#### 1. **Availability Management**
- Add new availability time slots
- Edit existing availabilities
- Delete availability slots
- Conflict detection for overlapping times

#### 2. **Smart UI Components**
- **Loading States**: Shows spinner while fetching data
- **Empty States**: User-friendly message when no availabilities exist
- **Error Handling**: Clear error messages with retry options
- **Past/Future Filter**: Toggle between showing all or only future availabilities

#### 3. **Form Validation**
- Date picker with future-only dates
- Time picker with proper validation
- Ensures start time is before end time
- Prevents overlapping time slots

#### 4. **Real-time Updates**
- Automatic refresh after adding/editing/deleting
- Provider-based state management for reactive UI
- Pull-to-refresh functionality

### 🎨 UI/UX Features

#### **Modern Design**
- Gradient backgrounds matching app theme
- Smooth animations and transitions
- Card-based layout with shadows
- Consistent with existing app design

#### **Accessibility**
- Clear visual hierarchy
- Proper color contrast
- Intuitive navigation
- Loading and error state feedback

#### **Responsive Layout**
- Works across different screen sizes
- Proper spacing and alignment
- Touch-friendly interactive elements

### 🔄 Navigation Integration

The availability management is seamlessly integrated into the app:

1. **Profile Screen**: Goalkeepers see an "Availability Management" card
2. **Navigation**: Direct route `/availability` for easy access
3. **Back Navigation**: Proper navigation stack handling

### 🚀 Usage

#### For Goalkeepers:
1. Navigate to Profile screen
2. If marked as goalkeeper, see "Gestão de Disponibilidade" card
3. Tap "Minha Disponibilidade" button
4. Use the + FAB to add new availability slots
5. Edit or delete existing slots as needed

#### For Players:
- Availabilities are accessible through the repository for booking features
- Can view goalkeeper schedules when making bookings

### 📱 Technical Implementation

#### **State Management**
- Uses Provider pattern for reactive state management
- Centralized controller handling all availability operations
- Proper error handling and loading states

#### **Data Layer**
- Repository pattern for clean separation of concerns
- Supabase integration with proper error handling
- Optimistic updates for better user experience

#### **UI Components**
- Reusable widgets for consistent design
- Proper widget composition
- Animation support for smooth interactions

### 🔧 Configuration

The feature requires:
1. Supabase configuration with the availabilities table
2. Proper RLS policies for security
3. Provider setup in main.dart
4. Route configuration for navigation

### 🎯 User Stories Fulfilled

✅ **Tarefa 3.1**: Tela de Gestão de Disponibilidade (UI)
- ✅ Nova tela "Minha Disponibilidade"
- ✅ Formulário para adicionar disponibilidade
- ✅ Lista de disponibilidades existentes
- ✅ Botão para remover disponibilidade

✅ **Tarefa 3.2**: Lógica de Interação com a Tabela `availabilities`
- ✅ CRUD operations (Create, Read, Update, Delete)
- ✅ Inserir nova disponibilidade
- ✅ Ler disponibilidades do guarda-redes
- ✅ Apagar disponibilidade

### 🚀 Future Enhancements
- Calendar view for better visualization
- Bulk operations for multiple time slots
- Recurring availability patterns
- Integration with booking system
- Push notifications for availability updates
