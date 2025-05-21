import 'package:eltest_exit/comps/how_to_pay.dart';
import 'package:flutter/material.dart';

// A simple Flutter dialog to input an API key.
class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  _ApiKeyDialogState createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  // Controller for the text field to get the entered API key.
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter API Key'),
      content: Column( // Use a Column to arrange multiple widgets vertically
        mainAxisSize: MainAxisSize.min, // Make the column take minimum space
        children: <Widget>[
          // New button to explain how to get the API key
          Align( // Align the button to the right
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement action for "how to get api key?"
                // This could open a new dialog with instructions,
                // navigate to a help page, or print to console.


                Navigator.pushReplacement( context, MaterialPageRoute(builder: (context) => const HowToPay()), );
               
                // Example: Show a simple message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Instructions on getting the API key go here!'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('how to get api key?'),
            ),
          ),
          const SizedBox(height: 8), // Add some spacing
          // The text field for entering the API key
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 56, 56, 56),
            ),
            decoration: const InputDecoration(
              hintText: 'Gemini API Key',
              border: OutlineInputBorder(),

            ),
            // Optional: Hide the input for sensitive keys
            // obscureText: true,
          ),
        ],
      ),
      actions: <Widget>[
        // Button to cancel the dialog.
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
        // Button to submit the entered API key.
        ElevatedButton(
          child: const Text('Submit'),
          onPressed: () {
            // Get the text from the input field.
            String apiKey = _apiKeyController.text;
            // You can now use the apiKey variable.
            // For example, pass it back to the calling widget:
            Navigator.of(context).pop(apiKey); // Close the dialog and return the API key
            // Or perform an action directly, like validating the key.
            print('Submitted API Key: $apiKey'); // Print for demonstration
          },
        ),
      ],
    );
  }
}