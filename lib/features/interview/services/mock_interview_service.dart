import 'dart:async';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/features/interview/models/interview_models.dart';

/// Mock interview service for development.
/// Simulates the interview flow without real API calls.
/// Will be replaced by real Supabase Edge Function calls later.
class MockInterviewService {
  static final Map<InterviewArea, List<String>> _questionBank = {
    InterviewArea.mobileDev: [
      'Para começar, me conte um pouco sobre sua trajetória profissional e como você chegou ao desenvolvimento mobile.',
      'Qual a diferença entre StatelessWidget e StatefulWidget no Flutter? Quando você usaria cada um?',
      'Como você gerencia estado em aplicações Flutter de médio a grande porte? Quais abordagens já utilizou?',
      'Descreva como você implementaria uma funcionalidade de cache offline em um app Flutter que consome uma API REST.',
      'Me fale sobre um bug complexo que você resolveu em produção em um app mobile. Como foi o processo de investigação?',
      'Como você lida com a comunicação entre plataforma nativa e Flutter? Já precisou usar Method Channels?',
      'Descreva sua abordagem para testes em aplicações Flutter. Quais tipos de teste você prioriza?',
      'Se você fosse arquitetar um app Flutter do zero para uma equipe de 5 desenvolvedores, qual seria a estrutura do projeto?',
    ],
    InterviewArea.webFrontend: [
      'Para começar, me conte sobre sua experiência com desenvolvimento frontend e quais frameworks já utilizou.',
      'Explique a diferença entre renderização do lado do cliente e do lado do servidor. Quando você usaria cada abordagem?',
      'Como você otimiza a performance de uma aplicação React com muitos componentes e re-renderizações frequentes?',
      'Descreva como você implementaria um sistema de autenticação com tokens JWT em uma SPA.',
      'Me conte sobre uma situação onde você precisou lidar com um problema de acessibilidade complexo. Como resolveu?',
      'Como você estrutura o gerenciamento de estado em uma aplicação frontend grande? Quais padrões já utilizou?',
      'Qual sua abordagem para garantir que uma aplicação web funcione bem em diferentes navegadores e dispositivos?',
      'Se você fosse migrar uma aplicação legada em jQuery para um framework moderno, qual seria sua estratégia?',
    ],
    InterviewArea.webBackend: [
      'Para começar, me conte sobre sua experiência com desenvolvimento backend e quais tecnologias domina.',
      'Explique como você projetaria uma API RESTful para um sistema de e-commerce. Quais decisões arquiteturais tomaria?',
      'Como você lida com escalabilidade em sistemas backend? Descreva estratégias que já utilizou.',
      'Descreva como você implementaria um sistema de filas para processamento assíncrono de tarefas.',
      'Me fale sobre um incidente em produção que você gerenciou. Como foi o processo de resposta e resolução?',
      'Como você implementa autenticação e autorização em uma API? Quais padrões de segurança considera essenciais?',
      'Explique sua abordagem para design de banco de dados. Como você decide entre SQL e NoSQL?',
      'Se você precisasse decompor um monolito em microserviços, qual seria seu plano de migração?',
    ],
    InterviewArea.databases: [
      'Para começar, me conte sobre sua experiência com bancos de dados e engenharia de dados.',
      'Explique a diferença entre índices clustered e non-clustered. Quando você criaria cada tipo?',
      'Como você otimizaria uma query SQL que está demorando mais de 30 segundos para executar?',
      'Descreva como você projetaria um data warehouse para análise de vendas de uma empresa de e-commerce.',
      'Me fale sobre um problema de inconsistência de dados que você enfrentou. Como identificou e resolveu?',
      'Como você implementaria replicação e alta disponibilidade em um banco de dados PostgreSQL?',
      'Explique as propriedades ACID e como elas se aplicam em sistemas distribuídos.',
      'Qual sua abordagem para migração de dados entre diferentes versões de schema em produção?',
    ],
    InterviewArea.devopsCloud: [
      'Para começar, me conte sobre sua experiência com DevOps e infraestrutura cloud.',
      'Como você configuraria um pipeline de CI/CD completo para uma aplicação que precisa ser deployada em múltiplos ambientes?',
      'Descreva como você orquestraria containers Docker em produção com Kubernetes.',
      'Explique sua estratégia de monitoramento e observabilidade para uma aplicação distribuída.',
      'Me fale sobre um incidente de infraestrutura que você resolveu. Qual foi o impacto e como mitigou?',
      'Como você implementaria Infrastructure as Code? Quais ferramentas e práticas utiliza?',
      'Descreva sua abordagem para gerenciamento de segredos e configurações em ambientes cloud.',
      'Se você precisasse reduzir custos de cloud em 40%, qual seria seu plano de otimização?',
    ],
    InterviewArea.qaTesting: [
      'Para começar, me conte sobre sua experiência com QA e testes de software.',
      'Como você definiria uma estratégia de testes para um novo projeto? Quais tipos de teste priorizaria?',
      'Descreva como você implementaria testes automatizados end-to-end para uma aplicação web.',
      'Explique sua abordagem para testes de performance e carga. Quais ferramentas já utilizou?',
      'Me fale sobre um bug crítico que escapou dos testes. O que falhou no processo e como você melhorou?',
      'Como você integraria testes de segurança no pipeline de desenvolvimento?',
      'Descreva como você gerencia dados de teste e ambientes de teste em projetos grandes.',
      'Qual sua abordagem para testes em arquiteturas de microserviços?',
    ],
    InterviewArea.security: [
      'Para começar, me conte sobre sua experiência com segurança da informação.',
      'Explique as principais vulnerabilidades do OWASP Top 10 e como você as previne.',
      'Como você implementaria um programa de segurança de aplicações em uma empresa?',
      'Descreva como você conduziria um pentest em uma aplicação web moderna.',
      'Me fale sobre um incidente de segurança que você gerenciou. Qual foi o processo de resposta?',
      'Como você implementaria criptografia de dados em repouso e em trânsito?',
      'Explique sua abordagem para gestão de identidades e acessos em uma organização.',
      'Qual seria sua estratégia para implementar Zero Trust em uma infraestrutura corporativa?',
    ],
    InterviewArea.architecture: [
      'Para começar, me conte sobre sua experiência com arquitetura de software e decisões técnicas de grande impacto.',
      'Como você decide entre uma arquitetura monolítica e microserviços para um novo projeto?',
      'Descreva como você implementaria o padrão CQRS com Event Sourcing em um sistema financeiro.',
      'Explique sua abordagem para garantir resiliência e tolerância a falhas em sistemas distribuídos.',
      'Me fale sobre uma decisão arquitetural difícil que você tomou. Quais trade-offs considerou?',
      'Como você lida com a evolução de APIs sem quebrar contratos existentes?',
      'Descreva como você implementaria Domain-Driven Design em um sistema complexo.',
      'Se você precisasse redesenhar um sistema legado com problemas de escalabilidade, qual seria sua abordagem?',
    ],
  };

  static final Map<InterviewArea, Map<int, String>> _idealAnswers = {
    InterviewArea.mobileDev: {
      1: 'Uma resposta ideal incluiria a definição clara: StatelessWidget é imutável e não mantém estado, enquanto StatefulWidget pode ter estado interno que muda durante o ciclo de vida. Deveria mencionar exemplos práticos e quando usar cada um, como usar StatelessWidget para UI estática e StatefulWidget para formulários ou animações.',
      2: 'Uma resposta completa mencionaria Riverpod, BLoC ou Provider como opções populares, explicando trade-offs de cada abordagem. Deveria abordar separação de concerns, testabilidade, e escalabilidade do gerenciamento de estado.',
      3: 'Deveria cobrir estratégias como SQLite/Hive para cache local, sincronização com servidor, tratamento de conflitos, indicadores visuais de modo offline, e queue de requests pendentes.',
    },
  };

  static List<String> getQuestionsForArea(InterviewArea area) {
    return _questionBank[area] ?? _questionBank[InterviewArea.mobileDev]!;
  }

  static String getIdealAnswer(InterviewArea area, int questionIndex) {
    final areaAnswers = _idealAnswers[area];
    if (areaAnswers != null && areaAnswers.containsKey(questionIndex)) {
      return areaAnswers[questionIndex]!;
    }
    return 'Uma resposta ideal deveria demonstrar conhecimento técnico profundo, '
        'uso de terminologia adequada, exemplos práticos de experiência real, '
        'e capacidade de articular conceitos complexos de forma clara e estruturada.';
  }

  /// Simulates generating a report after interview completion.
  static Future<InterviewSession> generateMockReport(
    InterviewSession session,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 3));

    final evaluatedQuestions = session.questions.map((q) {
      final scores = [65, 72, 80, 55, 88, 45, 78, 90];
      final evalIndex = q.questionOrder % scores.length;
      final score = scores[evalIndex];
      final evaluation = score >= 75
          ? QuestionEvaluation.good
          : score >= 50
              ? QuestionEvaluation.partial
              : QuestionEvaluation.insufficient;

      return q.copyWith(
        score: score,
        idealAnswer: getIdealAnswer(session.area, q.questionOrder),
        evaluation: evaluation,
      );
    }).toList();

    final technicalScore = 72;
    final clarityScore = 68;
    final fluencyScore = 75;
    final overallScore =
        ((technicalScore * AppConstants.technicalWeight) +
                (clarityScore * AppConstants.clarityWeight) +
                (fluencyScore * AppConstants.fluencyWeight))
            .round();

    final actionPlan = ActionPlan(
      id: 'mock-action-plan',
      interviewId: session.id,
      criticalPoints: [
        'Aprofundar conhecimento em padrões de arquitetura como Clean Architecture e MVVM',
        'Desenvolver respostas mais estruturadas usando o framework STAR para perguntas comportamentais',
      ],
      reviewPoints: [
        'Revisar conceitos de gerenciamento de estado avançado',
        'Praticar explicações sobre decisões técnicas com mais exemplos concretos',
        'Melhorar a articulação sobre trade-offs em escolhas de tecnologia',
      ],
      strengths: [
        'Boa capacidade de comunicação e clareza nas respostas',
        'Demonstra experiência prática sólida com exemplos reais',
        'Conhecimento técnico adequado para o nível da vaga',
      ],
      createdAt: DateTime.now(),
    );

    return session.copyWith(
      status: InterviewStatus.completed,
      overallScore: overallScore,
      technicalScore: technicalScore,
      clarityScore: clarityScore,
      fluencyScore: fluencyScore,
      questions: evaluatedQuestions,
      actionPlan: actionPlan,
    );
  }
}
