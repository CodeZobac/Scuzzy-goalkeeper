# Projeto Goalkeeper-Finder

## Visão Geral do Projeto
O Goalkeeper-Finder é uma aplicação web desenhada para conectar jogadores e equipas de futebol amador com guarda-redes disponíveis para alugar por jogo. A plataforma funciona de forma semelhante a um serviço "Uber", permitindo que os jogadores encontrem e agendem um guarda-redes com base na localização, disponibilidade e custo.

## Funcionalidades Principais
- **Busca e Filtragem:** Os jogadores podem procurar guarda-redes, filtrando por cidade.
- **Perfis de Utilizadores:** A aplicação terá dois tipos de utilizadores:
    - **Jogadores:** Podem procurar, agendar e avaliar guarda-redes.
    - **Guarda-redes:** Podem criar um perfil detalhado, definir o seu preço por jogo, gerir a sua disponibilidade e receber notificações de agendamento.
- **Gestão de Disponibilidade:** Os guarda-redes podem especificar as datas e horas em que estão livres para jogar.
- **Sistema de Agendamento:** Os jogadores podem selecionar um guarda-redes e marcar um jogo para uma data e hora específicas.
- **Notificações:** Os guarda-redes são notificados quando são selecionados para um jogo.
- **Avaliações e Comentários:** Após cada jogo, os jogadores podem avaliar o desempenho do guarda-redes (de 1 a 5 estrelas) e deixar um comentário.
- **Mapa de Campos:** Uma funcionalidade para visualizar campos de futebol. Os campos podem ser adicionados por utilizadores (ficando pendentes de aprovação) ou por administradores.

## Modelos de Dados

### 1. Utilizadores (`users`)
Armazena os dados de todos os utilizadores (jogadores e guarda-redes).

| Coluna | Tipo de Dados | Descrição/Notas |
| :--- | :--- | :--- |
| `id` | UUID | Chave Primária (PK) |
| `name` | Texto | Nome completo do utilizador. |
| `gender` | Texto | Sexo do utilizador. |
| `city` | Texto | Cidade de residência. |
| `birth_date` | Data | Para calcular a idade. |
| `club` | Texto | Clube atual ou anterior (opcional). |
| `nationality` | Texto | Nacionalidade. |
| `country` | Texto | País de residência. |
| `is_goalkeeper`| Booleano | `true` se o utilizador for um guarda-redes. |
| `price_per_game`| Decimal | Preço por jogo (apenas para guarda-redes). |
| `created_at` | Timestamp | Data de criação do registo. |

### 2. Disponibilidades (`availabilities`)
Regista os horários em que os guarda-redes estão disponíveis.

| Coluna | Tipo de Dados | Descrição/Notas |
| :--- | :--- | :--- |
| `id` | UUID | Chave Primária (PK) |
| `goalkeeper_id` | UUID | Chave Estrangeira (FK) para `users.id`. |
| `day` | Data | Dia da disponibilidade. |
| `start-time` | Hora | Hora de início da disponibilidade. |
| `end-time` | Hora | Hora de fim da disponibilidade. |

### 3. Agendamentos (`bookings`)
Armazena as informações sobre os jogos agendados.

| Coluna | Tipo de Dados | Descrição/Notas |
| :--- | :--- | :--- |
| `id` | UUID | Chave Primária (PK) |
| `player_id` | UUID | FK para `users.id` (quem marcou). |
| `goalkeeper_id` | UUID | FK para `users.id` (quem foi marcado). |
| `field_id` | UUID | FK para `fields.id` (opcional). |
| `game_datetime` | Timestamp | Data e hora do jogo. |
| `price` | Decimal | Preço do jogo no momento da marcação. |
| `status` | Texto | `pending`, `confirmed`, `completed`, `cancelled`. |
| `created_at` | Timestamp | Data de criação do registo. |

### 4. Avaliações (`ratings`)
Regista as avaliações feitas pelos jogadores aos guarda-redes.

| Coluna | Tipo de Dados | Descrição/Notas |
| :--- | :--- | :--- |
| `id` | UUID | Chave Primária (PK) |
| `booking_id` | UUID | FK para `bookings.id`. |
| `player_id` | UUID | FK para `users.id` (quem avaliou). |
| `goalkeeper_id` | UUID | FK para `users.id` (quem foi avaliado). |
| `rating` | Inteiro | Avaliação de 1 a 5. |
| `comment` | Texto | Comentário sobre o desempenho (opcional). |
| `created_at` | Timestamp | Data da avaliação. |

### 5. Campos (`fields`)
Armazena informações sobre os campos de futebol.

| Coluna | Tipo de Dados | Descrição/Notas |
| :--- | :--- | :--- |
| `id` | UUID | Chave Primária (PK) |
| `name` | Texto | Nome do campo. |
| `latitude` | Decimal | Coordenada de latitude. |
| `longitude` | Decimal | Coordenada de longitude. |
| `photo_url` | Texto | URL para uma foto do campo. |
| `status` | Texto | `approved`, `pending`. |
| `submitted_by` | UUID | FK para `users.id` (quem sugeriu o campo). |
| `created_at` | Timestamp | Data de criação do registo. |

## Tecnologias Sugeridas
- **Framework:** Flutter.
- **Linguagem:** Dart.
- **Backend & Base de Dados:** Supabase (PostgreSQL com PostGIS).
- **Mapa:** `flutter_map` com OpenStreetMap ou `google_maps_flutter`.
- **Autenticação:** Supabase Auth.
