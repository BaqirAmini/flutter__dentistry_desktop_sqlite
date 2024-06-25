import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Text('Need Help? Contact Us',
            style: Theme.of(context).textTheme.titleSmall),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.whatsapp, color: Colors.grey[600]),
                const SizedBox(width: 8.0),
                Text('(+93)79 21 95 121',
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: const Color.fromARGB(255, 116, 115, 115)))
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
