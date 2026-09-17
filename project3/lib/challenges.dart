class VerseChallenge {
  const VerseChallenge(this.excerpt, this.language, [this.aliases = const []]);
  final String excerpt;
  final String language;
  final List<String> aliases;
}

// Original short verses for this game's language challenge.
const verseChallenges = <VerseChallenge>[
  VerseChallenge('The moon is bright; the stars fill the night.', 'English'),
  VerseChallenge(
    'La luna brilla en el mar; las estrellas quieren cantar.',
    'Spanish',
    ['español', 'espanol'],
  ),
  VerseChallenge(
    'La lune éclaire la mer; les étoiles dansent dans l’air.',
    'French',
    ['français', 'francais'],
  ),
  VerseChallenge(
    'Der Mond scheint in der Nacht; ein Stern hält leise Wacht.',
    'German',
    ['deutsch'],
  ),
  VerseChallenge(
    'La luna splende sul mare; le stelle stanno a guardare.',
    'Italian',
    ['italiano'],
  ),
  VerseChallenge('A lua brilha no mar; as estrelas vão dançar.', 'Portuguese', [
    'português',
    'portugues',
  ]),
  VerseChallenge('De maan schijnt op de zee; de sterren dromen mee.', 'Dutch', [
    'nederlands',
  ]),
  VerseChallenge('月が海を照らす。星が夜を飾る。', 'Japanese', ['日本語']),
  VerseChallenge('月光洒在海面，星星点亮夜空。', 'Chinese', ['mandarin', '中文', '汉语', '漢語']),
  VerseChallenge('달빛이 바다를 비추고, 별빛이 밤을 수놓는다.', 'Korean', ['한국어']),
];

class MathChallenge {
  const MathChallenge(this.equation, this.answer);
  final String equation;
  final int answer;
}

const mathChallenges = <MathChallenge>[
  MathChallenge('7 + 5 = ?', 12),
  MathChallenge('9 × 3 = ?', 27),
  MathChallenge('48 ÷ 6 = ?', 8),
  MathChallenge('25 − 9 = ?', 16),
  MathChallenge('(6 + 4) × 3 = ?', 30),
  MathChallenge('7² = ?', 49),
  MathChallenge('81 ÷ 9 + 2 = ?', 11),
  MathChallenge('5 × 8 − 6 = ?', 34),
  MathChallenge('√64 = ?', 8),
  MathChallenge('2³ + 7 = ?', 15),
];
