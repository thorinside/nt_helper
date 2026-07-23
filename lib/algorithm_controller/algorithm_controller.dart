sealed class AlgorithmControllerNode {
  const AlgorithmControllerNode();
}

final class AlgorithmControllerColumn extends AlgorithmControllerNode {
  const AlgorithmControllerColumn({
    required this.children,
    this.gap = 12,
    this.padding = 0,
  });

  final List<AlgorithmControllerNode> children;
  final double gap;
  final double padding;
}

final class AlgorithmControllerRow extends AlgorithmControllerNode {
  const AlgorithmControllerRow({required this.children, this.gap = 8});

  final List<AlgorithmControllerNode> children;
  final double gap;
}

final class AlgorithmControllerSection extends AlgorithmControllerNode {
  const AlgorithmControllerSection({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<AlgorithmControllerNode> children;
}

final class AlgorithmControllerText extends AlgorithmControllerNode {
  const AlgorithmControllerText({
    required this.text,
    this.style = 'body',
    this.align = 'start',
  });

  final String text;
  final String style;
  final String align;
}

final class AlgorithmControllerSlider extends AlgorithmControllerNode {
  const AlgorithmControllerSlider({
    required this.label,
    required this.parameterNumber,
    this.minimum,
    this.maximum,
    this.enabled = true,
  });

  final String label;
  final int parameterNumber;
  final int? minimum;
  final int? maximum;
  final bool enabled;
}

final class AlgorithmControllerToggle extends AlgorithmControllerNode {
  const AlgorithmControllerToggle({
    required this.label,
    required this.parameterNumber,
    this.onValue = 1,
    this.offValue = 0,
    this.enabled = true,
  });

  final String label;
  final int parameterNumber;
  final int onValue;
  final int offValue;
  final bool enabled;
}

enum AlgorithmControllerActionType { setParameter, adjustParameter }

final class AlgorithmControllerAction {
  const AlgorithmControllerAction.setParameter({
    required this.parameterNumber,
    required int this.value,
  }) : type = AlgorithmControllerActionType.setParameter,
       delta = null;

  const AlgorithmControllerAction.adjustParameter({
    required this.parameterNumber,
    required int this.delta,
  }) : type = AlgorithmControllerActionType.adjustParameter,
       value = null;

  final AlgorithmControllerActionType type;
  final int parameterNumber;
  final int? value;
  final int? delta;
}

final class AlgorithmControllerButton extends AlgorithmControllerNode {
  const AlgorithmControllerButton({
    required this.label,
    required this.action,
    this.style = 'filled',
    this.enabled = true,
  });

  final String label;
  final AlgorithmControllerAction action;
  final String style;
  final bool enabled;
}

final class AlgorithmControllerDivider extends AlgorithmControllerNode {
  const AlgorithmControllerDivider();
}

final class AlgorithmControllerSpacer extends AlgorithmControllerNode {
  const AlgorithmControllerSpacer({this.size = 8});

  final double size;
}

sealed class AlgorithmControllerCanvasShape {
  const AlgorithmControllerCanvasShape();
}

final class AlgorithmControllerCircle extends AlgorithmControllerCanvasShape {
  const AlgorithmControllerCircle({
    required this.x,
    required this.y,
    required this.radius,
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
  });

  final double x;
  final double y;
  final double radius;
  final String? fill;
  final String? stroke;
  final double strokeWidth;
}

final class AlgorithmControllerLine extends AlgorithmControllerCanvasShape {
  const AlgorithmControllerLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.stroke = 'outline',
    this.strokeWidth = 1,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final String stroke;
  final double strokeWidth;
}

final class AlgorithmControllerRectangle
    extends AlgorithmControllerCanvasShape {
  const AlgorithmControllerRectangle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.radius = 0,
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double radius;
  final String? fill;
  final String? stroke;
  final double strokeWidth;
}

final class AlgorithmControllerCanvas extends AlgorithmControllerNode {
  const AlgorithmControllerCanvas({
    required this.semanticsLabel,
    required this.shapes,
    this.aspectRatio = 4,
  });

  final String semanticsLabel;
  final double aspectRatio;
  final List<AlgorithmControllerCanvasShape> shapes;
}

final class AlgorithmControllerDocument {
  const AlgorithmControllerDocument({
    required this.version,
    required this.title,
    required this.root,
  });

  final int version;
  final String title;
  final AlgorithmControllerNode root;
}

final class AlgorithmControllerDefinition {
  const AlgorithmControllerDefinition({
    required this.id,
    required this.algorithmGuid,
    required this.name,
    required this.assetPath,
  });

  final String id;
  final String algorithmGuid;
  final String name;
  final String assetPath;
}

final class AlgorithmControllerRegistry {
  const AlgorithmControllerRegistry(this._definitions);

  static const bundled = AlgorithmControllerRegistry([
    AlgorithmControllerDefinition(
      id: 'builtin.euclidean-patterns',
      algorithmGuid: 'eucp',
      name: 'Euclidean controller',
      assetPath: 'assets/algorithm_controllers/euclidean_patterns.lua',
    ),
  ]);

  final List<AlgorithmControllerDefinition> _definitions;

  AlgorithmControllerDefinition? findForGuid(String guid) {
    for (final definition in _definitions) {
      if (definition.algorithmGuid == guid) return definition;
    }
    return null;
  }
}
