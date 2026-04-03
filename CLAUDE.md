# Axion — Claude Code Project Memory

## Visão Geral do Projeto

App mobile Flutter (iOS + Android) de simulação de entrevistas técnicas 
para profissionais de TI. A IA entrevistadora fala por voz (ElevenLabs), 
o usuário responde por voz (Whisper), e o app gera relatórios detalhados 
pós-sessão. App pago na loja (one-time purchase) — sem qualquer compra 
dentro do app. Idioma: Português Brasileiro (PT-BR).

---

## Comandos Essenciais

```bash
# Rodar o app
flutter run

# Gerar código Riverpod (rodar após alterar qualquer arquivo com @riverpod)
dart run build_runner build --delete-conflicting-outputs

# Watcher contínuo durante desenvolvimento
dart run build_runner watch --delete-conflicting-outputs

# Análise estática
flutter analyze

# Testes
flutter test

# Build iOS (sem codesign)
flutter build ios --no-codesign

# Build Android debug
flutter build apk --debug

# Deploy Edge Functions (Supabase CLI)
supabase functions deploy generate-questions
supabase functions deploy evaluate-answer
supabase functions deploy generate-report
supabase functions deploy transcribe
supabase functions deploy tts
```

---

## Arquitetura
lib/
├── main.dart # Init: Supabase, dotenv, ProviderScope, GoRouter, dark theme
├── core/
│ ├── theme/app_theme.dart # Dark theme, #0D0D0F bg, #7B5EF8 accent, Inter font
│ ├── router/app_router.dart # GoRouter + ShellRoute (TabBar) + route guards
│ ├── constants/app_constants.dart # Enums, table names, area/level values
│ ├── services/supabase_service.dart # Singleton Supabase client wrapper
│ └── widgets/ # Componentes reutilizáveis (AxionButton, AxionCard, etc.)
├── features/
│ ├── splash/ # Logo animado + redirect logic
│ ├── onboarding/ # 3 slides informativos (sem paywall)
│ ├── auth/ # Login/cadastro email+senha (Supabase Auth)
│ ├── profile_setup/ # Onboarding de perfil: nome → área → senioridade
│ ├── home/ # Aba 1: saudação + botão iniciar + últimas 3 sessões
│ ├── interview/ # Feature principal (setup, pre, sessão ao vivo, encerrado)
│ │ ├── data/ # interview_repository.dart
│ │ ├── models/ # interview_models.dart (entidades + enums)
│ │ ├── presentation/ # setup, pre_interview, interview, interview_ended, completion
│ │ ├── providers/ # interview_providers.dart (Riverpod)
│ │ └── services/ # interview_service.dart + audio_service.dart
│ ├── report/ # Relatório completo pós-entrevista
│ ├── history/ # Aba 2: lista + gráfico fl_chart + filtros
│ └── profile/ # Aba 3: exibir/editar perfil + sign out
supabase/
└── functions/
├── generate-questions/index.ts
├── evaluate-answer/index.ts
├── generate-report/index.ts
├── transcribe/index.ts
└── tts/index.ts

text

---

## Navegação (GoRouter)
/splash
/onboarding → guard: nunca viu onboarding
/auth → guard: não autenticado
/profile-setup → guard: onboarding_completed = false
/home (ShellRoute) → guard: autenticado
/home → Aba 1
/history → Aba 2
/profile → Aba 3
/setup → fora da TabBar (full-screen)
/pre-interview → fora da TabBar
/interview → fora da TabBar
/interview-ended → fora da TabBar
/completion → parâmetro obrigatório: interviewId
/report/:id → fora da TabBar

text

---

## State Management

Riverpod com code generation (`@riverpod`). Padrão por feature:

- `AsyncNotifierProvider` → operações async (auth, banco, chamadas de API)
- `StateNotifierProvider` → estado complexo local (sessão de entrevista ativa)
- `Provider` → serviços e repositórios (singletons)

**Sempre rodar `build_runner` após modificar arquivos com `@riverpod`.**

---

## Banco de Dados (Supabase PostgreSQL)

Tabelas: `users`, `interviews`, `interview_questions`, `action_plans`

**Campos críticos:**
- `users.onboarding_completed` — controla redirect para /profile-setup
- `users.preferred_area` e `users.seniority_level` — pré-selecionados no setup da entrevista
- `interviews.ended_early` — true quando usuário saiu do app durante sessão
- `interviews.status` — 'in_progress' | 'completed' | 'ended_early'

RLS habilitado em todas as tabelas. Usuário acessa apenas seus próprios dados.
Políticas: SELECT, INSERT, UPDATE e DELETE em todas as tabelas.

---

## Edge Functions (Supabase)

**REGRA ABSOLUTA: chaves de API (OpenAI, ElevenLabs) NUNCA no código Flutter.**
Todo tráfego de IA passa exclusivamente pelas Edge Functions.
O app Flutter só se comunica com o Supabase.

| Função | Responsabilidade |
|--------|-----------------|
| `generate-questions` | GPT-4o → array de 6-8 perguntas calibradas por área/nível/vaga |
| `evaluate-answer` | GPT-4o → avalia resposta + decide follow-up ou próxima pergunta |
| `generate-report` | GPT-4o → relatório completo: scores, análise por pergunta, plano de ação |
| `transcribe` | Whisper → transcrição do áudio do usuário (form-data) |
| `tts` | ElevenLabs Turbo v2.5 PT-BR → stream mp3 da fala da IA |

---

## Regras de Negócio — NUNCA VIOLAR

**[1] SEM COMPRAS NO APP**
Sem in_app_purchase, paywall ou RevenueCat. Pagamento = comprar o app na loja.
Quem instalou tem acesso total e ilimitado. Sem limites de uso.

**[2] CÂMERA OBRIGATÓRIA NA ENTREVISTA**
- Permissão de câmera E microfone exigidas antes de iniciar
- Permissão negada → entrevista bloqueada (nunca silenciosamente ignorar)
- Preview PiP (picture-in-picture) do usuário visível durante toda sessão
- Câmera NÃO grava nem envia vídeo ao servidor — apenas sensor local

**[3] ENCERRAMENTO POR SAÍDA DO APP**
- `WidgetsBindingObserver` ativo SOMENTE durante entrevista ativa
- `AppLifecycleState.paused` ou `.inactive` → encerrar sessão imediatamente
- Ao retornar: tela `interview_ended_screen` com mensagem de desclassificação
- Salvar com `ended_early: true` — sem score, sem relatório completo
- Em todas as outras telas: comportamento normal do lifecycle

**[4] SEM PRODUÇÃO DE CÓDIGO**
- App 100% por voz. Sem campos de código, editores ou input técnico.
- IA nunca pede para escrever código — sempre perguntas verbais.

**[5] IA POR VOZ COM LEGENDA**
- ElevenLabs TTS: IA fala em PT-BR
- Texto da IA aparece na tela sincronizado com o áudio (legenda em tempo real)
- Whisper: transcreve resposta do usuário
- GPT-4o: follow-up dinâmico baseado na qualidade da resposta
- 6 a 8 perguntas por sessão

**[6] RELATÓRIO SALVO ATOMICAMENTE**
- Gerado e salvo em uma única chamada ao finalizar a entrevista
- Nunca navegar para /report com dados incompletos
- Se falhar: snackbar de erro + opção de tentar novamente
- Contador de entrevistas: decrementar APENAS ao concluir (não ao iniciar)

---

## Pacotes de Áudio

- **Gravação do usuário:** `record ^5.2.0` (único pacote de captura)
- **Waveform visual:** widget customizado alimentado pela amplitude do `record`
- **NÃO usar** `audio_waveforms` — conflito de `AVAudioSession` no iOS
- **Playback da IA:** `just_audio`

---

## Variáveis de Ambiente (.env)
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key

text

Chaves de API (OpenAI, ElevenLabs) são Supabase Secrets — nunca no .env do app.

---

## Design

- Tema: dark mode padrão (sem toggle — sempre dark)
- Background: `#0D0D0F`
- Accent: `#7B5EF8` (roxo Axion)
- Fonte: Inter (Google Fonts)
- Avatar da IA: animated pulse widget simples (sem assets externos, sem Lottie)
- Bundle ID: `com.axion.app`
- Sem emojis como elementos de design — usar ícones (Material/Cupertino)

---

## Convenções de Código

- Dart 3.x com null safety estrito
- Sem `dynamic` — sempre tipar explicitamente
- `const` em todo widget/valor imutável
- Nomes em inglês no código, strings de UI em PT-BR
- Um widget por arquivo
- Separar lógica de negócio da UI — providers nunca importam widgets
- Tratar todos os estados: loading, error, empty, success
- `AsyncValue.when()` para estados async no Riverpod