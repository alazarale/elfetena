import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HowToPay extends StatefulWidget {
  const HowToPay({Key? key}) : super(key: key);

  @override
  State<HowToPay> createState() => _HowToPayState();
}

class _HowToPayState extends State<HowToPay> {
  int _current = 0;
  final CarouselSliderController  _controller = CarouselSliderController ();
  final List<String> imgList = [
    'assets/images/01.jpg',
    'assets/images/02.jpg',
    'assets/images/03.jpg',
    'assets/images/04.jpg',
    'assets/images/05.jpg',
    'assets/images/06.jpg',
    'assets/images/07.jpg',
    'assets/images/08.jpg',
    'assets/images/09.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final devWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(255, 255, 255, 255)),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_sharp,
                size: 20,
                color: Color(0xff0081B9),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xffF2F5F8),
        title: const Center(
          child: Text(
            "How To Pay",
            style: TextStyle(
              color: const Color(0xff21205A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: Color(0xffCBCDD1),
      body: SingleChildScrollView(
        child: Column(children: [
          SizedBox(
            height: deviceHeight-200,
            child: CarouselSlider(
              items: imgList
                  .map((item) => Container(
                        child: Container(
                          child: Image.asset(
                            item,
                            fit: BoxFit.cover,
                            height: deviceHeight - 200,
                          ),
                        ),
                      ))
                  .toList(),
              carouselController: _controller,
              options: CarouselOptions(
                  height: deviceHeight,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imgList.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }
}
