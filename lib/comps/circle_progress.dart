import 'package:eltest_exit/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CircularProgressForResult extends StatelessWidget {
  double perc;
  int right;
  int tot;

  CircularProgressForResult(this.perc, this.right, this.tot, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
    child: Container(
    width: 200,
    height: 200,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppTheme.colorE1E9F9,
    ),
    child: Center(
      child: Container(
        width: 200,
        height: 200,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CircularPercentIndicator(
                    radius: 100.0,
                    lineWidth: 15,
                    percent: perc / 100,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${perc.toStringAsFixed(1)}%",
                          style: TextStyle(
                            color: AppTheme.color0081B9,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${right}/${tot}',
                          style: TextStyle(
                            color: AppTheme.color0081B9,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    progressColor: AppTheme.color0081B9,
                    backgroundColor: AppTheme.colorE1E9F9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}
