/// Hamro Kosh's actual, literal bylaws — 16 numbered rules, grouped exactly
/// as the reference design (`design_spec.md` §3, screen `4b`) groups them,
/// supplied verbatim by the fund's own committee (not placeholder/lorem
/// copy). These same numbers drive the loan-eligibility logic in
/// `lib/core/models/loan_category.dart` and the penalty calculation in
/// `functions/index.js` — this file is the human-readable statement of the
/// same rules those enforce in code.
class TermsRule {
  const TermsRule(this.number, this.textEn, this.textNe);
  final int number;
  final String textEn;
  final String textNe;
}

class TermsGroup {
  const TermsGroup(this.titleEn, this.titleNe, this.rules);
  final String titleEn;
  final String titleNe;
  final List<TermsRule> rules;
}

const List<TermsGroup> termsGroups = [
  TermsGroup('Depositing', 'जम्मा गर्ने', [
    TermsRule(1, 'The fund will be deposited monthly.', 'कोषमा रकम मासिक रूपमा जम्मा गरिनेछ।'),
    TermsRule(
      2,
      'Minimum monthly amount should be NPR 250.',
      'न्यूनतम मासिक रकम रु. २५० हुनुपर्छ।',
    ),
    TermsRule(
      3,
      'Amount should be deposited monthly or quarterly.',
      'रकम मासिक वा त्रैमासिक रूपमा जम्मा गर्न सकिन्छ।',
    ),
    TermsRule(
      7,
      'Any deposit on a special occasion (birthdays, anniversaries, etc.) '
          'is appreciated.',
      'जन्मदिन, वार्षिकोत्सव जस्ता विशेष अवसरमा गरिने थप योगदानलाई प्रोत्साहन गरिन्छ।',
    ),
  ]),
  TermsGroup('Using the fund', 'कोषको प्रयोग', [
    TermsRule(
      4,
      'Fund health should be reviewed quarterly.',
      'कोषको अवस्था त्रैमासिक रूपमा समीक्षा गरिनेछ।',
    ),
    TermsRule(
      5,
      "The deposited amount should be utilized based on the members' "
          'alignment.',
      'जम्मा भएको रकम सदस्यहरूको सहमतिका आधारमा प्रयोग गरिनेछ।',
    ),
    TermsRule(6, 'This will be a non-profit fund.', 'यो नाफारहित कोष हो।'),
  ]),
  TermsGroup('Borrowing', 'ऋण लिने', [
    TermsRule(
      8,
      'Fund members can take a loan from the fund.',
      'कोषका सदस्यहरूले कोषबाट ऋण लिन सक्नेछन्।',
    ),
    TermsRule(
      9,
      'A maximum of 2 members can hold a loan at a time; no loan will be '
          'disbursed while 2 loans are already pending.',
      'एकैपटक बढीमा २ जना सदस्यले मात्र ऋण लिन सक्नेछन्; २ वटा ऋण बाँकी रहेसम्म नयाँ ऋण दिइने छैन।',
    ),
    TermsRule(
      10,
      'A loan can be taken under different categories.',
      'ऋण विभिन्न प्रकार (श्रेणी) मा लिन सकिन्छ।',
    ),
    TermsRule(
      11,
      'Personal category — a member can borrow up to 30% of the amount '
          'remaining in the fund. The principal and interest should be '
          'deposited within the quarter, starting from the date of loan '
          'disbursement.',
      'व्यक्तिगत श्रेणी: कोषमा बाँकी रहेको रकमको ३०% सम्म ऋण लिन सकिन्छ। साँवा र ब्याज ऋण दिएको '
          'मितिदेखि एक त्रैमासभित्र तिर्नुपर्छ।',
    ),
    TermsRule(
      12,
      'Personal category interest rate is 1% monthly, 12% per annum, of '
          'the principal amount.',
      'व्यक्तिगत श्रेणीको ब्याजदर साँवा रकमको मासिक १%, वार्षिक १२% हुनेछ।',
    ),
    TermsRule(
      13,
      'Emergency category — a member can borrow up to 80% of the amount '
          'remaining in the fund. This category covers medical or '
          'accidental emergencies only. The amount should be deposited '
          'within 1 to 2 quarters, starting from the date of loan '
          'disbursement.',
      'आकस्मिक श्रेणी: कोषमा बाँकी रहेको रकमको ८०% सम्म ऋण लिन सकिन्छ, स्वास्थ्य वा दुर्घटना '
          'आकस्मिकताका लागि मात्र। रकम ऋण दिएको मितिदेखि १ देखि २ त्रैमासभित्र तिर्नुपर्छ।',
    ),
    TermsRule(
      14,
      'Emergency category interest rate is 0.5% monthly, 6% per annum.',
      'आकस्मिक श्रेणीको ब्याजदर मासिक ०.५%, वार्षिक ६% हुनेछ।',
    ),
  ]),
  TermsGroup('Interest and penalty', 'ब्याज र जरिवाना', [
    TermsRule(
      15,
      'Interest should be deposited monthly or quarterly, based on '
          'availability.',
      'ब्याज उपलब्धताका आधारमा मासिक वा त्रैमासिक रूपमा बुझाउनुपर्छ।',
    ),
    TermsRule(
      16,
      'If interest is not deposited within the given time frame, an '
          'additional 1.5% monthly penalty interest will be imposed on the '
          'principal amount, from the start date of loan disbursement. If '
          'the amount is still not deposited by the next payment date, '
          'another 1.5% is added on top.',
      'तोकिएको समयभित्र ब्याज नबुझाएमा, ऋण दिएको मितिदेखि साँवा रकममा थप मासिक १.५% जरिवाना '
          'लाग्नेछ। अर्को भुक्तानी मितिसम्म पनि नतिरेमा थप १.५% थपिनेछ।',
    ),
  ]),
];
