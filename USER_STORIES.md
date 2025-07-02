
# User Stories - Goalkeeper-Finder

Este documento detalha as user stories para o desenvolvimento da aplicação Goalkeeper-Finder. Cada história é desenhada para ser compreendida e implementada por um Large Language Model (LLM), com sub-tarefas claras e a stack tecnológica definida.

**Stack Tecnológica Principal:**
- **Frontend:** Flutter (Dart)
- **Backend & Base de Dados:** Supabase (PostgreSQL, Auth, Edge Functions)
- **Mapas:** `flutter_map` com OpenStreetMap

---

## Feature 1: Autenticação e Gestão de Perfis de Utilizador

**User Story:** Como utilizador, quero poder registar-me, fazer login e gerir o meu perfil para poder utilizar a aplicação como jogador ou como guarda-redes, mantendo os meus dados atualizados.

### Tarefa 1.1: Configuração da Autenticação no Supabase
- **Descrição:** Configurar o sistema de autenticação do Supabase para a aplicação, utilizando o método de email e palavra-passe.
- **Sub-tarefas:**
    - Ativar o provider de "Email" na secção de Autenticação do dashboard do Supabase.
    - Configurar os templates de email (confirmação de registo, recuperação de palavra-passe).
- **Stack:** Supabase Auth.

### Tarefa 1.2: Criação das Telas de Autenticação (UI)
- **Descrição:** Desenvolver as interfaces de utilizador para as telas de Registo (Sign Up) e Login (Sign In).
- **Sub-tarefas:**
    - Criar um formulário de registo com campos para `nome`, `email` e `palavra-passe`.
    - Criar um formulário de login com campos para `email` e `palavra-passe`.
    - Implementar a navegação entre as telas de login e registo.
- **Stack:** Flutter, Dart.

### Tarefa 1.3: Implementação da Lógica de Autenticação
- **Descrição:** Conectar as telas de UI com o cliente Supabase para gerir o estado de autenticação do utilizador.
- **Sub-tarefas:**
    - Implementar a função `signUp` utilizando `supabase.auth.signUp()`.
    - Implementar a função `signIn` utilizando `supabase.auth.signInWithPassword()`.
    - Gerir o estado da sessão do utilizador na aplicação, redirecionando-o para a tela principal após o login.
    - Implementar a função `signOut`.
- **Stack:** Flutter, Dart, `supabase_flutter`.

### Tarefa 1.4: Criação e Gestão do Perfil de Utilizador
- **Descrição:** Permitir que o utilizador visualize e edite os seus dados pessoais, que serão armazenados na tabela `users`.
- **Sub-tarefas:**
    - Criar uma tela de "Perfil" que exibe os dados do utilizador logado.
    - Desenvolver um formulário de edição para os campos: `name`, `gender`, `city`, `birth_date`, `club`, `nationality`, `country`.
    - Implementar um `trigger` no Supabase que, após um novo registo na `auth.users`, cria uma entrada correspondente na tabela `public.users`.
    - Implementar a lógica para atualizar os dados na tabela `users` utilizando o cliente Supabase.
- **Stack:** Flutter, Dart, `supabase_flutter`, SQL (PostgreSQL Triggers).

### Tarefa 1.5: Definição do Tipo de Perfil (Guarda-redes)
- **Descrição:** Permitir que um utilizador se identifique como guarda-redes, definindo o seu preço por jogo.
- **Sub-tarefas:**
    - Na tela de Perfil, adicionar um switch ou checkbox para o campo `is_goalkeeper`.
    - Se `is_goalkeeper` for `true`, exibir um campo para o utilizador inserir o `price_per_game`.
    - A interface deve ser condicional para mostrar opções específicas de guarda-redes apenas se o perfil estiver marcado como tal.
- **Stack:** Flutter, Dart, `supabase_flutter`.

---

## Feature 2: Busca e Filtragem de Guarda-Redes

**User Story:** Como jogador, quero poder procurar guarda-redes disponíveis e filtrá-los por cidade para encontrar facilmente um para o meu jogo.

### Tarefa 2.1: Criação da Tela de Busca (UI)
- **Descrição:** Desenvolver a interface de utilizador para a tela de busca de guarda-redes.
- **Sub-tarefas:**
    - Adicionar uma barra de pesquisa na parte superior da tela.
    - Incluir um botão ou ícone para aplicar filtros.
    - Criar uma lista para exibir os resultados da busca, mostrando o nome, cidade e preço do guarda-redes.
- **Stack:** Flutter, Dart.

### Tarefa 2.2: Implementação da Lógica de Busca e Filtragem
- **Descrição:** Consultar a base de dados Supabase para obter a lista de guarda-redes com base nos critérios de busca.
- **Sub-tarefas:**
    - Implementar uma função que consulta a tabela `users`.
    - A consulta deve filtrar por `is_goalkeeper = true`.
    - Adicionar um filtro opcional na consulta para o campo `city`, que será preenchido pelo utilizador.
    - A busca pode ser acionada ao digitar na barra de pesquisa ou ao clicar num botão.
- **Stack:** Flutter, Dart, `supabase_flutter` (PostgREST).

---

## Feature 3: Gestão de Disponibilidade do Guarda-Redes

**User Story:** Como guarda-redes, quero poder definir e gerir os meus horários de disponibilidade para que os jogadores saibam quando me podem agendar.

### Tarefa 3.1: Tela de Gestão de Disponibilidade (UI)
- **Descrição:** Criar uma interface onde o guarda-redes possa adicionar, visualizar e remover os seus horários disponíveis.
- **Sub-tarefas:**
    - Desenvolver uma nova tela chamada "Minha Disponibilidade".
    - Criar um formulário para adicionar uma nova disponibilidade com campos para `day` (data), `start-time` (hora de início) e `end-time` (hora de fim).
    - Exibir as disponibilidades existentes numa lista ou calendário.
    - Adicionar um botão para remover uma disponibilidade.
- **Stack:** Flutter, Dart.

### Tarefa 3.2: Lógica de Interação com a Tabela `availabilities`
- **Descrição:** Implementar as operações de CRUD (Create, Read, Update, Delete) para a tabela `availabilities`.
- **Sub-tarefas:**
    - Função para inserir uma nova disponibilidade (`INSERT` na tabela `availabilities`).
    - Função para ler todas as disponibilidades de um guarda-redes (`SELECT` na tabela `availabilities` onde `goalkeeper_id` corresponde ao utilizador logado).
    - Função para apagar uma disponibilidade (`DELETE` na tabela `availabilities`).
- **Stack:** Flutter, Dart, `supabase_flutter`.

---

## Feature 4: Sistema de Agendamento de Jogos

**User Story:** Como jogador, quero poder selecionar um guarda-redes, ver a sua disponibilidade e agendar um jogo para uma data e hora específicas.

### Tarefa 4.1: Tela de Agendamento (UI)
- **Descrição:** Criar a interface para o processo de agendamento de um guarda-redes.
- **Sub-tarefas:**
    - A partir do perfil de um guarda-redes, adicionar um botão "Agendar Jogo".
    - Criar uma tela de agendamento que mostre as disponibilidades do guarda-redes (lidas da tabela `availabilities`).
    - Adicionar um seletor de data e hora (`DateTimePicker`) para o jogador escolher o `game_datetime`.
    - Adicionar um campo opcional para selecionar um campo de futebol (da tabela `fields`).
- **Stack:** Flutter, Dart.

### Tarefa 4.2: Lógica de Criação de Agendamento (`bookings`)
- **Descrição:** Implementar a lógica para criar um novo registo na tabela `bookings`.
- **Sub-tarefas:**
    - Ao confirmar o agendamento, validar se a data e hora escolhidas estão dentro da disponibilidade do guarda-redes.
    - Inserir um novo registo na tabela `bookings` com os IDs do jogador e do guarda-redes, a data/hora do jogo, o preço (copiado do `price_per_game` do guarda-redes) e o `status` inicial como `'pending'`.
- **Stack:** Flutter, Dart, `supabase_flutter`.

---

## Feature 5: Sistema de Notificações

**User Story:** Como guarda-redes, quero receber uma notificação sempre que um jogador me agendar para um jogo, para que eu possa confirmar ou rejeitar o pedido.

### Tarefa 5.1: Configuração de Triggers e Edge Functions
- **Descrição:** Criar um mecanismo no backend para enviar uma notificação quando um novo agendamento é criado.
- **Sub-tarefas:**
    - Criar um `trigger` na tabela `bookings` que é acionado em cada `INSERT`.
    - O `trigger` deve invocar uma `Edge Function` do Supabase.
    - A `Edge Function` será responsável por construir e enviar a notificação.
- **Stack:** SQL (PostgreSQL Triggers), TypeScript (Supabase Edge Functions).

### Tarefa 5.2: Implementação do Envio e Receção de Notificações
- **Descrição:** Configurar um serviço de push notifications (como o Firebase Cloud Messaging - FCM) e integrá-lo na aplicação Flutter.
- **Sub-tarefas:**
    - A `Edge Function` enviará a notificação para o serviço de push (FCM).
    - A aplicação Flutter deve ser configurada para receber as push notifications.
    - Ao receber uma notificação, a aplicação deve exibi-la ao utilizador (guarda-redes).
- **Stack:** Flutter, Dart, `firebase_messaging`, Supabase Edge Functions.

---

## Feature 6: Avaliações e Comentários

**User Story:** Como jogador, quero poder avaliar o desempenho de um guarda-redes e deixar um comentário após um jogo concluído, para ajudar outros jogadores a fazerem as suas escolhas.

### Tarefa 6.1: Tela de Avaliação (UI)
- **Descrição:** Criar uma interface para o jogador submeter a sua avaliação.
- **Sub-tarefas:**
    - Após um agendamento ter o `status` alterado para `'completed'`, o jogador deve ver uma opção para "Avaliar Guarda-redes".
    - Criar uma tela de avaliação com um seletor de estrelas (1 a 5) e um campo de texto para o `comment`.
- **Stack:** Flutter, Dart.

### Tarefa 6.2: Lógica de Submissão de Avaliação
- **Descrição:** Implementar a lógica para guardar a avaliação na tabela `ratings`.
- **Sub-tarefas:**
    - Ao submeter o formulário, inserir um novo registo na tabela `ratings`, associando-o ao `booking_id`, `player_id` e `goalkeeper_id`.
- **Stack:** Flutter, Dart, `supabase_flutter`.

---

## Feature 7: Mapa de Campos de Futebol

**User Story:** Como utilizador, quero poder visualizar um mapa com os campos de futebol disponíveis e sugerir novos campos para serem adicionados à plataforma.

### Tarefa 7.1: Tela do Mapa (UI)
- **Descrição:** Desenvolver uma tela que exiba um mapa interativo.
- **Sub-tarefas:**
    - Integrar o widget `flutter_map` na aplicação.
    - Configurar o OpenStreetMap como provedor de mapas.
- **Stack:** Flutter, Dart, `flutter_map`.

### Tarefa 7.2: Exibição dos Campos no Mapa
- **Descrição:** Obter os dados dos campos da base de dados e mostrá-los como marcadores no mapa.
- **Sub-tarefas:**
    - Consultar a tabela `fields` para obter todos os campos com `status = 'approved'`.
    - Para cada campo, adicionar um marcador no mapa utilizando as suas coordenadas `latitude` e `longitude`.
- **Stack:** Flutter, Dart, `flutter_map`, `supabase_flutter`.

### Tarefa 7.3: Sugestão de Novos Campos
- **Descrição:** Permitir que os utilizadores sugiram novos campos de futebol.
- **Sub-tarefas:**
    - Criar um formulário de "Sugerir Campo" com campos para `name` e `photo_url`.
    - Permitir que o utilizador clique no mapa para definir as coordenadas `latitude` e `longitude`.
    - Ao submeter, inserir um novo registo na tabela `fields` com o `status = 'pending'` e o `submitted_by` preenchido com o ID do utilizador logado.
- **Stack:** Flutter, Dart, `supabase_flutter`.
