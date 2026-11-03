# Raptor Run

Jogo estilo "dinossauro do Chrome" (corredor infinito, pula pra desviar de
obstáculos), mas colorido, com moedas colecionáveis durante a corrida e
resgate diário de recompensa. Feito em Flutter puro (sem engine externa),
pra rodar em Android e iOS a partir do mesmo código.

> A pasta do projeto continua se chamando `jogo-dinossauro` (nome interno,
> não aparece pra quem joga) — só o nome visível do app mudou pra
> **Raptor Run**.

## O que já está pronto
- Tela inicial com o personagem em destaque, moedas totais, recorde, botão
  de resgate diário, e atalhos pra Loja e Config (`lib/screens/home_screen.dart`).
- Resgate diário com sequência de recompensa crescente por dias seguidos
  (dia 1 = 10 moedas ... dia 7 = 50 moedas, depois recomeça), salvo em
  `lib/services/daily_reward_service.dart`.
- Jogo em si (`lib/screens/game_screen.dart`): pula (toque/deslize/botão) e
  abaixa (deslize/botão) pra desviar dos obstáculos, moedas coloridas
  aparecem enquanto corre, pontuação = distância percorrida.
  - **Dificuldade = só velocidade.** Começa numa velocidade base e só vai
    acelerando com a distância (sem teto de verdade — ver `maxExtraSpeed`
    em `game_screen.dart`, é só uma trava de segurança bem alta). Os
    obstáculos sempre vêm aleatórios, mas a física do pulo garante que todo
    obstáculo é sempre pulável (ver nota de fairness mais abaixo) — a
    corrida fica mais difícil só por ficar mais rápida, nunca por um
    obstáculo impossível.
  - 🦖 **Dino** (único personagem por enquanto): silhueta preta/cinza-escura
    angulosa com boca de verdade aberta (vão vazado, não só uma linha),
    parecida com o dino original do Chrome (`character_renderer.dart`). O
    pássaro voa reto numa altura fixa vindo em cima do personagem no eixo X
    (só o cenário se move — o pássaro não sobe nem desce), igual ao jogo
    original.
  - **Três fases**, todas resolvidas por distância percorrida em
    `resolveWorldStyle()` (`lib/game/world_style.dart`):
    1. **Dia**: cactos coloridos, passarinhos fofos, prédios ao fundo com
       variação de telhado (reto/antena/caixa d'água) e tonalidade.
    2. **Extinção** (depois de `extinctionDistance`): vulcões ao fundo,
       obstáculos viram rocha, pássaros viram pterodáctilo.
    3. **Noite** (depois de `nightDistance`): volta pro cenário da cidade,
       só que de noite — céu escuro, lua com crateras, janelas dos prédios
       acesas (padrão de quais estão acesas varia por prédio).
  - Nuvens mais orgânicas, aviãozinho cruzando o céu de vez em quando (só
    de dia) e tufos de grama no chão — tudo em `dino_painter.dart`.
- **Explicação de como jogar** na primeira vez que a pessoa entra na tela do
  jogo (`_TutorialDialog` em `game_screen.dart`), não aparece de novo depois.
- Progresso salvo no aparelho via `shared_preferences`
  (`lib/services/storage_service.dart`): moedas totais, recorde,
  preferências de som e controle.
- Tudo desenhado por código (`lib/game/dino_painter.dart` +
  `character_renderer.dart`) — não depende de nenhum arquivo de
  imagem/sprite.
- Sons de pulo, moeda e fim de jogo, mais música de fundo em loop
  (`lib/services/audio_service.dart`). Todos os áudios em `assets/audio/`
  são **sintetizados por código** (`tool/generate_audio.dart`, ondas
  senoidais/quadradas/triangulares calculadas na mão), zero risco de
  direitos autorais.
- Loja (`lib/screens/shop_screen.dart`): por enquanto só mostra o Dino e um
  aviso de "em breve" pra Personagens, Skins e Especiais — ainda não
  decidimos quais personagens/skins novos entram (ver "Próximos passos").
- Configurações (`lib/screens/settings_screen.dart`): ligar/desligar música,
  ligar/desligar efeitos sonoros, e escolher entre deslizar na tela ou
  botões na tela pra pular/abaixar.

## Rodando o jogo
Abra um terminal **novo** (pra pegar o PATH atualizado) nesta pasta e rode:

```bash
flutter emulators --launch Pixel_8
flutter run
```

Ou com um celular Android conectado com depuração USB habilitada, só
`flutter run` já detecta o aparelho.

## Testar rápido no navegador (opcional, sem precisar de emulador)
```bash
flutter run -d web-server --web-port 8765
```
Depois abra `http://localhost:8765` no navegador. Bom só pra conferir a
lógica/visual rapidamente — a versão final continua sendo pro Android/iOS.

## Estrutura
```
lib/
  main.dart                     ponto de entrada do app
  screens/
    home_screen.dart            tela inicial (moedas, recorde, resgate diário, loja, config)
    game_screen.dart            tela do jogo (loop, física, colisão, HUD, sons, tutorial)
    shop_screen.dart            loja (por enquanto só "em breve")
    settings_screen.dart        som e esquema de controle
  game/
    entities.dart                modelos de obstáculo, pássaro e colecionável
    dino_painter.dart            desenho do céu/chão/obstáculos/voadores/itens
    character_renderer.dart      desenho do personagem, reusado no jogo e no preview da loja
    characters.dart              lista de personagens (hoje: só o Dino, grátis)
    skins.dart                   lista de skins (hoje: só a clássica)
    world_style.dart             resolve o cenário (cores/obstáculo/voador) pela distância percorrida
  services/
    storage_service.dart         leitura/escrita local (moedas, recorde, config)
    daily_reward_service.dart    regra do resgate diário
    audio_service.dart           toca efeitos sonoros e a música de fundo
assets/audio/                    sons sintetizados (ver tool/generate_audio.dart)
tool/generate_audio.dart         script que gera os .wav — rodar de novo só se
                                  quiser trocar/adicionar algum som
```

## Sobre a dificuldade (pra manter em mente ao mexer no jogo)
O único jeito de o jogo ficar mais difícil é a velocidade (`_speed` em
`game_screen.dart`), que cresce com a distância sem teto de verdade na
prática. Os obstáculos continuam surgindo em posições/tipos aleatórios, mas
a física do pulo (altura máxima ~136px) sempre consegue passar por cima de
qualquer obstáculo (altura máxima 80px) — ou seja, nenhum obstáculo é
"impossível", só fica mais apertado no tempo de reação conforme acelera. Se
for mexer nesses números no futuro, vale manter essa relação (altura máxima
do pulo bem acima da altura máxima dos obstáculos) pra não quebrar essa
garantia.

## Testando as fases (dia/extinção/noite) rapidinho
As fases só trocam depois de uma distância percorrida bem longa
(`extinctionDistance` e `nightDistance` em `world_style.dart`, hoje 3000 e
6000) — se quiser ver as transições rápido sem jogar minutos seguidos, dá
pra baixar esses dois números temporariamente nesse arquivo, testar, e
devolver ao valor original depois (já testei assim, com valores baixos, e
as três fases trocam certinho).

## Ideias pra próximos passos (não implementadas ainda)
- Mais personagens (skins e personagens novos ainda não foram decididos —
  a loja já tem a seção "Personagens" e "Skins" prontas, com preço já
  pronto pra vender; é só decidir quais entram e criar o `CharacterDef`/
  `Skin` e o desenho correspondente).
- Especiais/power-ups na loja (já tem uma seção reservada "✨ Especiais" na
  tela da loja, só com aviso de "em breve" por enquanto).
- Recompensa diária com mais variedade (não só moedas).
- Anúncios ou compra dentro do app, se quiser monetizar.
- Publicar na Google Play / App Store (cada uma exige conta de
  desenvolvedor paga: Google ~US$25 único, Apple ~US$99/ano).
