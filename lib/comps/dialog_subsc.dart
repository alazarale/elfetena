// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:chapasdk/chapasdk.dart';
import 'package:provider/provider.dart';

import 'provider/strored_ref.dart';
import 'dart:math';
import '../theme/app_theme.dart';

class SubscriptionDialog extends StatefulWidget {
  SubscriptionDialog({Key? key})
      : super(key: key);

  @override
  _SubscriptionDialogState createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  TextEditingController first_name = TextEditingController();
  TextEditingController last_name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  Random random = Random();

  bool isloading = true;
  String? ref_no;

  @override
  void initState() {
    super.initState();
    Provider.of<RefData>(context, listen: false).tryGetCredintial();
    first_name.text = Provider.of<RefData>(context, listen: false).firstName;
    last_name.text = Provider.of<RefData>(context, listen: false).lastName;
    email.text = Provider.of<RefData>(context, listen: false).email;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.padding),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Visibility(
        visible: isloading,
        child: contentBox(context),
        replacement: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
              left: Constants.padding,
              top: Constants.avatarRadius + Constants.padding,
              right: Constants.padding,
              bottom: Constants.padding),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
              ]),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pay Using Chapa.',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.color7E7E7E,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/how-to', arguments: {});
                  },
                  child: Text('How to Pay?'),
                ),
                TextFormField(
                  controller: first_name,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.color7E7E7E,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    focusColor: Colors.white,
                    //add prefix icon

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    fillColor: Colors.grey,

                    hintText: "First Name",

                    //make hint text
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),

                    //create lable
                    labelText: 'First Name',
                    //lable style
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  controller: last_name,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.color7E7E7E,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    focusColor: Colors.white,
                    //add prefix icon

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    fillColor: Colors.grey,

                    hintText: "Last Name",

                    //make hint text
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),

                    //create lable
                    labelText: 'Last Name',
                    //lable style
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: phone,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.color7E7E7E,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    focusColor: Colors.white,

                    //add prefix icon
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    fillColor: Colors.grey,

                    hintText: "Phone #",

                    //make hint text
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),

                    //create lable
                    labelText: 'Phone #',
                    //lable style
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  controller: email,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.color7E7E7E,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    focusColor: Colors.white,
                    //add prefix icon

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    fillColor: Colors.grey,

                    hintText: "Email",

                    //make hint text
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),

                    //create lable
                    labelText: 'Email',
                    //lable style
                    labelStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontFamily: "verdana_regular",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.green),
                          ),
                          onPressed: paying,
                          child: Text(
                            'Continue',
                            style: TextStyle(fontSize: 18),
                          )),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 18),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: Constants.padding,
          right: Constants.padding,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: Constants.avatarRadius,
            child: ClipRRect(
                borderRadius:
                    BorderRadius.all(Radius.circular(Constants.avatarRadius)),
                child: Image.asset("assets/images/chapa.png")),
          ),
        ),
      ],
    );
  }

  paying() {
    String datetime = DateTime.now().toString();
    datetime = datetime.replaceAll('-', '');
    datetime = datetime.replaceAll(':', '');
    datetime = datetime.replaceAll('.', '');
    datetime = datetime.replaceAll(' ', '');

    ref_no = 'subscpay' +
        random.nextInt(10).toString() +
        'sid' +
        datetime +
        random.nextInt(100).toString();
    Provider.of<RefData>(context, listen: false).setSubRef(ref_no);
    Provider.of<RefData>(context, listen: false)
        .saveCredintial(first_name.text, last_name.text, email.text, phone.text);
    print(ref_no);
    Chapa.paymentParameters(
      context: context, // context
      publicKey: 'CHAPUBK-Yi1zAN9XeIiwfAMxWSHWuqMcEJZzVf2z',
      currency: 'ETB',
      amount: '3',
      email: email.text,
      phone: '0911111111',
      firstName: first_name.text,
      lastName: first_name.text,
      txRef: ref_no!,
      title: 'Subscription',
      desc: 'El-Test subscription',
      namedRouteFallBack: '/subsc', 
      nativeCheckout: true,
      showPaymentMethodsOnGridView: true,
      onPaymentFinished: (message, reference, amount) {
        Navigator.pop(context);
      },// fall back route name
    );
    setState(() {
      isloading = false;
    });
  }
}

class Constants {
  Constants._();
  static const double padding = 20;
  static const double avatarRadius = 45;
}
