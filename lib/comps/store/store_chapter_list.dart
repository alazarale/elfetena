import 'package:eltest_exit/comps/service/remote_services.dart';
import 'package:eltest_exit/models/chapter_model.dart';
import 'package:flutter/material.dart';

class StoreChapList extends StatefulWidget {
  const StoreChapList({Key? key}) : super(key: key);

  @override
  State<StoreChapList> createState() => _StoreChapListState();
}

class _StoreChapListState extends State<StoreChapList> {
  String? _subName;
  int? _subId;
  List<ChapterModel>? chapters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement initState
    super.didChangeDependencies();
    Map arguments = ModalRoute.of(context)?.settings.arguments as Map;
    _subName = arguments['sub_name'];
    _subId = arguments['sub_id'];
    getData();
  }

  getData() async {
    isLoading = false;
    chapters = await ChaptersFetch().getsubs(_subId);
    if (chapters != null) {
      print(chapters);
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
              padding: const EdgeInsets.fromLTRB(20, 10, 0, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.store,
                    size: 24,
                    color: Color.fromARGB(255, 48, 45, 179),
                  ),
                  Text(
                    ' > ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 48, 45, 179),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        color: Color.fromARGB(255, 48, 45, 179),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Text(
                    ' > ',
                    style: TextStyle(
                      color: Color.fromARGB(255, 48, 45, 179),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Chapters',
                      style: TextStyle(
                        color: Color.fromARGB(255, 48, 45, 179),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
              child: ListView.builder(
                itemCount: chapters?.length,
                physics: ScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Navigator.pushNamed(context, '/store-chap-list',
                      //     arguments: {
                      //       'sub_name': chapte?[index].name,
                      //       'sub_id': subjects?[index].id
                      //     });
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${chapters?[index].unit}',
                                    maxLines: 2,
                                    textAlign: TextAlign.justify,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xff0081B9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: devWidth - 150,
                                    child: Text(
                                      '${chapters?[index].name}',
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Color.fromARGB(255, 126, 126, 126),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}
