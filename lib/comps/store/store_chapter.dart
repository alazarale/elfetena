import 'package:flutter/material.dart';

import '../../models/subject_model.dart';
import '../service/remote_services.dart';

class StoreChapterSub extends StatefulWidget {
  const StoreChapterSub({Key? key}) : super(key: key);

  @override
  State<StoreChapterSub> createState() => _StoreChapterSubState();
}

class _StoreChapterSubState extends State<StoreChapterSub> {
  List<Subject>? subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    getData();

    // This widget is the root of your application.
  }

  getData() async {
    isLoading = false;
    subjects = await SubjectsFetch().getsubs();
    if (subjects != null) {
      print(subjects);
      setState(() {
        isLoading = true;
      });
    }
  }
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
        elevation: 1,
        backgroundColor: const Color(0xffF2F5F8),
        title: const Center(
          child: Text(
            "Store",
            style: TextStyle(
              color: const Color(0xff21205A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xffF2F5F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Choose Subject',
                    style: TextStyle(
                      color: Color(0xff21205A),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  
                ],
              ),
            ),
            SizedBox(
              height: deviceHeight - 80,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
                child: ListView.builder(
                  itemCount: subjects?.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/store-chap-list',
                              arguments: {
                                'sub_name': subjects?[index].name,
                                'sub_id': subjects?[index].id
                              });
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${subjects?[index].name}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 126, 126, 126),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
  }
}