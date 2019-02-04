import 'package:flutter/widgets.dart';
import 'dart:math' show pi;
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

class TransformPlayground extends StatefulWidget {
  const TransformPlayground({
    Key key,
  }) : super(key: key);

  @override
  TransformPlaygroundState createState() {
    return new TransformPlaygroundState();
  }
}

class TransformPlaygroundState extends State<TransformPlayground>
    with SingleTickerProviderStateMixin<TransformPlayground> {
  AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this,
        lowerBound: -0.5,
        upperBound: 0.5,
        duration: Duration(
          seconds: 8,
        ));
    controller.forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.reverse();
      }
      if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Color.fromRGBO(0xaa, 0, 0x66, 1),
        ),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final width = constraints.maxWidth;
              final r = -100 + constraints.maxHeight / 2;
              final deltaX = width * controller.value;
              final alpha = 2 * math.asin(width / 2 / r);
              final dxRate = -deltaX / width;
              final rotation = dxRate * alpha / 2;
              final maxTranslationY = r - r * math.cos(alpha / 2);
              final translationY = dxRate.abs() * maxTranslationY;
              return Stack(
                children: [
                  Center(
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..translate(deltaX, -translationY, 0)
                        ..rotateZ(rotation),
                      child: Container(
                        color: Color.fromRGBO(0x83, 0x42, 0xfa, 1.0),
                        height: 200,
                        width: 200,
                        child: Center(
                            child: Text(
                          "${controller.value.toStringAsFixed(3)}",
                          style: TextStyle(color: Color(0xffc6df8f)),
                        )),
                      ),
                    ),
                  ),
                  Align(
                    child: Container(
                      decoration: ShapeDecoration(
                        shape: CircleBorder(),
                        color: Color.fromRGBO(0xf3, 0xc2, 0x4a, 1.0),
                      ),
                      width: 10,
                      height: 10,
                    ),
                    alignment: Alignment.topCenter,
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}
