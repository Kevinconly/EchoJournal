import '../entities/journal_entry.dart';
import '../entities/mood.dart';

class ReflectionEngine {
  static const Map<String, List<String>> _keywordPrompts = {
    'stress': [
      'What specific situation or thought caused this stress?',
      'How did this stress manifest in your body or mind?',
      'What coping mechanisms helped you deal with this stress?',
    ],
    'stressed': [
      'What was the main source of your stress today?',
      'How did your body react to this stressful feeling?',
      'What helped you feel even slightly less stressed?',
    ],
    'happy': [
      'What specific moments brought you the most joy today?',
      'How did this happiness affect your overall mood?',
      'What can you do to recreate this feeling tomorrow?',
    ],
    'joy': [
      'What sparked this feeling of joy?',
      'How did this joy impact your day?',
      'Who or what contributed to this joyful moment?',
    ],
    'excited': [
      'What are you most looking forward to?',
      'How does this excitement make you feel about the future?',
      'What steps can you take to prepare for this exciting event?',
    ],
    'excitement': [
      'What's fueling this excitement?',
      'How long have you been anticipating this?',
      'What does this excitement tell you about your values?',
    ],
    'tired': [
      'What activities or responsibilities drained your energy today?',
      'How did your body signal that it needed rest?',
      'What would help you recharge effectively?',
    ],
    'exhausted': [
      'What pushed you to the point of exhaustion?',
      'How can you protect your energy better in the future?',
      'What does your body and mind truly need right now?',
    ],
    'sad': [
      'What thoughts or events contributed to this sadness?',
      'How does this sadness feel in your body?',
      'What comfort or support do you need right now?',
    ],
    'sadness': [
      'What triggered this feeling of sadness?',
      'How can you be gentle with yourself during this time?',
      'What small thing might bring even a moment of relief?',
    ],
    'angry': [
      'What boundary or value was violated that caused this anger?',
      'How did you express or process this anger?',
      'What does this anger tell you about what matters to you?',
    ],
    'anger': [
      'What injustice or frustration sparked this anger?',
      'How can you channel this energy constructively?',
      'What needs to be said or done to resolve this?',
    ],
    'anxious': [
      'What specific worries are circulating in your mind?',
      'How does anxiety show up in your body?',
      'What would help you feel more grounded right now?',
    ],
    'anxiety': [
      'What uncertain situation is triggering this anxiety?',
      'What's the worst-case scenario, and how likely is it?',
      'What small action could help you regain a sense of control?',
    ],
    'calm': [
      'What helped you achieve this sense of calm?',
      'How can you cultivate more of this peaceful feeling?',
      'What practices or environments support your tranquility?',
    ],
    'peaceful': [
      'What contributed to this peaceful state?',
      'How does this calm feel different from your usual state?',
      'What can you learn from this moment of peace?',
    ],
    'grateful': [
      'What specific blessings or good fortune are you recognizing?',
      'How does gratitude shift your perspective on your day?',
      'Who or what deserves your appreciation right now?',
    ],
    'gratitude': [
      'What unexpected goodness did you experience today?',
      'How does practicing gratitude affect your mood?',
      'What often-overlooked blessings can you acknowledge?',
    ],
    'proud': [
      'What accomplishment or quality are you proud of?',
      'How does this pride connect to your values or goals?',
      'Who else might be proud of your achievements?',
    ],
    'confident': [
      'What strengthened your confidence today?',
      'How does this confidence feel in your body?',
      'What can you do with this newfound assurance?',
    ],
    'lonely': [
      'What triggered this feeling of loneliness?',
      'What connection or support do you truly need right now?',
      'How can you reach out even in small ways?',
    ],
    'overwhelmed': [
      'What specific responsibilities or thoughts feel like too much?',
      'How can you break this down into manageable pieces?',
      'What could you let go of, even temporarily?',
    ],
    'confused': [
      'What decision or situation feels unclear?',
      'What information or clarity do you need?',
      'How can you sit with this uncertainty without rushing?',
    ],
    'disappointed': [
      'What expectation wasn't met that led to this disappointment?',
      'How can you reframe this situation with self-compassion?',
      'What can you learn from this unmet expectation?',
    ],
  };

  static const Map<String, List<String>> _moodPrompts = {
    'Happy': [
      'What made today particularly good?',
      'How did this happiness show up in your interactions?',
      'What can you celebrate about yourself today?',
    ],
    'Calm': [
      'What helped you find this inner peace?',
      'How does this calm feel different from your usual state?',
      'What practices supported this tranquility?',
    ],
    'Sad': [
      'What emotions are beneath this sadness?',
      'How can you be gentle with yourself right now?',
      'What support do you need during this time?',
    ],
    'Stressed': [
      'What demands are feeling most pressing right now?',
      'How is your body responding to this stress?',
      'What would help you feel even slightly more at ease?',
    ],
    'Excited': [
      'What possibilities are you most enthusiastic about?',
      'How does this excitement shape your outlook?',
      'What steps can you take to move toward this excitement?',
    ],
  };

  static List<String> generateReflectionPrompts(JournalEntryEntity entry) {
    final List<String> prompts = [];
    final Set<String> usedPrompts = {};

    // Analyze text for keywords
    final text = entry.text.toLowerCase();
    final detectedKeywords = _detectKeywords(text);

    // Add keyword-based prompts
    for (final keyword in detectedKeywords) {
      final keywordPromptList = _keywordPrompts[keyword];
      if (keywordPromptList != null) {
        // Add up to 2 prompts from each detected keyword
        final availablePrompts = keywordPromptList
            .where((prompt) => !usedPrompts.contains(prompt))
            .take(2);
        
        for (final prompt in availablePrompts) {
          prompts.add(prompt);
          usedPrompts.add(prompt);
        }
      }
    }

    // Add mood-based prompts if we need more
    if (prompts.length < 3) {
      final moodPromptList = _moodPrompts[entry.mood.label];
      if (moodPromptList != null) {
        final neededPrompts = 3 - prompts.length;
        final availableMoodPrompts = moodPromptList
            .where((prompt) => !usedPrompts.contains(prompt))
            .take(neededPrompts);
        
        for (final prompt in availableMoodPrompts) {
          prompts.add(prompt);
          usedPrompts.add(prompt);
        }
      }
    }

    // Add general reflection prompts if still needed
    if (prompts.length < 3) {
      final generalPrompts = [
        'What patterns do you notice in your reactions today?',
        'How does this experience connect to your values?',
        'What would you tell a friend going through this?',
        'What strength did you discover in yourself today?',
        'How might you approach this differently next time?',
      ];
      
      final neededPrompts = 3 - prompts.length;
      final availableGeneralPrompts = generalPrompts
          .where((prompt) => !usedPrompts.contains(prompt))
          .take(neededPrompts);
      
      prompts.addAll(availableGeneralPrompts);
    }

    return prompts.take(3).toList();
  }

  static List<String> _detectKeywords(String text) {
    final detectedKeywords = <String>[];
    
    for (final keyword in _keywordPrompts.keys) {
      if (text.contains(keyword)) {
        detectedKeywords.add(keyword);
      }
    }
    
    return detectedKeywords;
  }

  static String generateInitialReflection(JournalEntryEntity entry) {
    final mood = entry.mood.label;
    final detectedKeywords = _detectKeywords(entry.text.toLowerCase());
    
    // Create contextual opening based on mood and keywords
    String opening = '';
    
    switch (mood) {
      case 'Happy':
        opening = "I can see you're feeling happy! 🌟 ";
        break;
      case 'Calm':
        opening = "You're feeling calm - that's wonderful! 🌊 ";
        break;
      case 'Sad':
        opening = "I hear that you're feeling sad. 💙 ";
        break;
      case 'Stressed':
        opening = "I sense you're stressed. 🌿 ";
        break;
      case 'Excited':
        opening = "Your excitement is palpable! 🎆 ";
        break;
      default:
        opening = "Thank you for sharing this moment. 🌱 ";
    }
    
    // Add keyword-specific context
    if (detectedKeywords.isNotEmpty) {
      final primaryKeyword = detectedKeywords.first;
      switch (primaryKeyword) {
        case 'tired':
        case 'exhausted':
          opening += "It sounds like your energy is low. ";
          break;
        case 'overwhelmed':
          opening += "There's a lot on your mind right now. ";
          break;
        case 'grateful':
        case 'gratitude':
          opening += "It's beautiful that you're practicing gratitude. ";
          break;
        case 'proud':
        case 'confident':
          opening += "Your self-assurance is wonderful to see. ";
          break;
        case 'lonely':
          opening += "Connection is important, and I'm here with you. ";
          break;
      }
    }
    
    opening += "Here are some questions to help you reflect more deeply:";
    
    return opening;
  }

  static String generateContextualResponse(String userMessage, JournalEntryEntity entry) {
    final message = userMessage.toLowerCase();
    
    // Respond to specific themes in the user's reflection
    if (message.contains('help') || message.contains('advice')) {
      return "I'm here to support your reflection process. Remember that you already have wisdom within you - sometimes we just need the right questions to access it. What feels most important to explore right now?";
    }
    
    if (message.contains('feel') || message.contains('feeling')) {
      return "Your feelings are valuable signals from your inner self. By acknowledging them without judgment, you're already practicing self-awareness. What else are you noticing about how you feel?";
    }
    
    if (message.contains('why') || message.contains('reason')) {
      return "Understanding 'why' can be enlightening, but sometimes the answer unfolds gradually. What insights are emerging as you sit with this question?";
    }
    
    if (message.contains('how') && (message.contains('deal') || message.contains('handle'))) {
      return "Finding healthy ways to navigate challenges is a strength. What strategies have worked for you in the past, and what might you try differently this time?";
    }
    
    if (message.contains('thank') || message.contains('grateful')) {
      return "Gratitude is such a powerful practice. It shifts our focus to what's working and good in our lives. What other blessings might you be overlooking?";
    }
    
    if (message.contains('learn') || message.contains('understand')) {
      return "Every experience offers lessons when we're open to them. What's the biggest insight you're gaining from this reflection?";
    }
    
    // Default supportive response
    return "Thank you for sharing that with me. Your willingness to explore your thoughts and feelings shows great self-awareness. What else feels important to acknowledge or explore?";
  }
}
