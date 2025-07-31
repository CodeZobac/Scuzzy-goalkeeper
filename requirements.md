
# Requisitos e Melhorias

Este documento detalha os requisitos, bugs e melhorias necessárias para a aplicação Goalkeeper-Finder.

## Página Announcements L

- **Filtros não funcionais:** Ao clicar nos filtros, nada é selecionado embora a interface não responde. Quando um filtro é selecionado, os filtros devem colapsar.

## Ecrã de Autenticação L

- **Botões cortados:** Os botões no ecrã de autenticação estão visualmente cortados, afetando a usabilidade.
- **Funcionalidade "Esqueceu a palavra-passe":** A opção "Esqueceu a palavra-passe" exibe uma mensagem de "em desenvolvimento" e deve ser implementada.
- **Navegação bloqueada:** Após clicar no botão "Esqueceu a Password", o utilizador fica preso no ecrã de login sem possibilidade de voltar atrás.

## Mapa e Filtros(eu)

- **Mapa com problemas:** O mapa apresenta um comportamento instável e não funciona como esperado.
- **Sobreposição de dados verificados:** Uma faixa verde com a mensagem "dados verificados" sobrepõe-se ao mapa, obstruindo a visibilidade. Deve aparecer a opção de excluir a mensagem E SE O UTILIZADOR CLICAR NO X NUNCA MAIS DEVE APARECER.
- **Localização do utilizador:** O mapa deve detetar a localização do utilizador, centrar a visualização nesse ponto e exibir os campos, jogadores e guarda-redes próximos.
- **Zoom e clusters descentrados:** Ao fazer zoom ou clicar num cluster de marcadores, o mapa fica descentrado.
- **Navegação por cidade:** Clicar numa cidade na lista de filtros não redireciona o mapa para a cidade selecionada.
- **Validação de cidades:** O sistema permite a inserção de cidades que não existem. Apenas cidades válidas (obtidas da base de dados) devem ser permitidas.
- **Estilo da modal de filtros:** A modal de filtros tem um esquema de cores diferente do resto da aplicação. Deve seguir o padrão de design (branco e verde).
- **Lógica de filtros do mapa:**
    - A seleção de uma cidade no filtro deve navegar o mapa para essa cidade.
    - Deve ser possível filtrar por "Jogadores", "Campos" e "Guarda-redes". Por defeito, todos devem ser exibidos.
- **Dados dinâmicos para cidades:** A lista de cidades no filtro deve ser carregada dinamicamente a partir da base de dados.
- **Botão "Contratar":** O botão "Contratar" quando clico no mapa em cima de um guarda-redes não tem nenhuma ação associada. É necessário definir e implementar a sua funcionalidade. Aparece A redecionar para agendamento... E depois não sai do sítio.

## Perfis de Utilizador L

- **Interface do perfil de convidado:** Os botões na página de perfil, quando o utilizador está em modo convidado, estão visualmente confusos e precisam de ser redesenhados para maior clareza.

## Anúncios(eu)

- **Símbolo da moeda:** O símbolo do dólar ($) deve ser substituído pelo símbolo do euro (€) em todos os ecrãs de posts.
- **Informação de distância:**
    - No cartão de detalhes do anúncio, a informação sobre a distância até ao campo de futebol só deve ser exibida se o utilizador tiver a localização ativada.
    - A distância (ex: "2km de distância") deve ser claramente referenciada à localização atual do utilizador. Se a permissão de localização não for concedida, esta informação não deve ser mostrada.

## Experiência de Convidado e UI Geral(eu)

- **Imagens dinâmicas:** NO post, quando clicado, nos detalhes na parte do campo as imagens devem ser carregadas dinamicamente. Quando não houver imagens disponíveis, deve ser exibida uma mensagem a informar o utilizador (ex: "Nenhuma imagem disponível").
- **Botão "Login" intrusivo:** Em modo convidado, o botão "Login" sobrepõe-se a outros elementos da interface em algumas vistas, dificultando a interação.
- **Idioma da aplicação:** Todo o texto gerado e exibido na aplicação deve estar em português de Portugal.
