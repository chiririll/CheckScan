enum AssistParseError { empty, noProducts, nothingToApply }

class AssistMatchedPosition {
  const AssistMatchedPosition({
    required this.positionId,
    required this.displayName,
    required this.confidence,
    required this.rawLine,
  });

  final String positionId;
  final String displayName;
  final double confidence;
  final String rawLine;
}

class AssistUnmatchedLine {
  const AssistUnmatchedLine({required this.raw});

  final String raw;
}

class AssistDraftProduct {
  const AssistDraftProduct({required this.name, this.positions = const []});

  final String name;
  final List<AssistMatchedPosition> positions;

  AssistDraftProduct copyWith({String? name, List<AssistMatchedPosition>? positions}) {
    return AssistDraftProduct(name: name ?? this.name, positions: positions ?? this.positions);
  }
}

class AssistDraft {
  const AssistDraft({this.products = const [], this.unmatched = const []});

  final List<AssistDraftProduct> products;
  final List<AssistUnmatchedLine> unmatched;

  bool get isEmpty => products.isEmpty && unmatched.isEmpty;

  bool get canApply => products.any((product) => product.positions.isNotEmpty);

  AssistDraft renameProduct(int index, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return this;
    return AssistDraft(
      products: [
        for (var i = 0; i < products.length; i++) i == index ? products[i].copyWith(name: trimmed) : products[i],
      ],
      unmatched: unmatched,
    );
  }

  AssistDraft withoutProduct(int index) {
    return AssistDraft(
      products: [for (var i = 0; i < products.length; i++) if (i != index) products[i]],
      unmatched: unmatched,
    );
  }

  AssistDraft withoutPosition(int productIndex, String positionId) {
    return AssistDraft(
      products: [
        for (var i = 0; i < products.length; i++)
          if (i == productIndex)
            products[i].copyWith(
              positions: [for (final position in products[i].positions) if (position.positionId != positionId) position],
            )
          else
            products[i],
      ],
      unmatched: unmatched,
    );
  }

  AssistDraft withoutUnmatched(int index) {
    return AssistDraft(
      products: products,
      unmatched: [for (var i = 0; i < unmatched.length; i++) if (i != index) unmatched[i]],
    );
  }
}

class AssistParseResult {
  const AssistParseResult.ok(this.draft) : error = null;
  const AssistParseResult.fail(this.error) : draft = null;

  final AssistDraft? draft;
  final AssistParseError? error;

  bool get isOk => draft != null && error == null;
}
