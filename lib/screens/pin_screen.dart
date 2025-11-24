import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinScreen extends StatefulWidget {
  final bool isSetting;
  const PinScreen({super.key, required this.isSetting});

  @override
  State<StatefulWidget> createState() {
    return _PinScreenState();
  }
}

class _PinScreenState extends State<PinScreen> {
  String _inputPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;

  void _onKeyPressed(String value) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += value;
      });

      if (_inputPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDelete() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      });
    }
  }

  Future<void> _handlePinComplete() async {
    await Future.delayed(Duration(milliseconds: 150));

    if (widget.isSetting) {
      if (!_isConfirming) {
        setState(() {
          _confirmPin = _inputPin;
          _inputPin = '';
          _isConfirming = true;
        });
      } else {
        if (_inputPin == _confirmPin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_pin', _inputPin);
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("PIN SET SUCCESSFULLY!")));
          }
        } else {
          setState(() {
            _inputPin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("PIN DID NOT MATCHED! Try Again.")),
            );
          }
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final String? storedPin = prefs.getString("user_pin");

      if (_inputPin == storedPin) {
        if (mounted) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _inputPin = '';
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("INCORRECT PIN!")));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String message = widget.isSetting
        ? (_isConfirming ? "Confirm you PIN" : "Seat a new PIN")
        : "Enter PIN to unlock";

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(leading: CloseButton()),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 12),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _inputPin.length
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              );
            }),
          ),
          SizedBox(height: 60),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox(); // Empty bottom left
                if (index == 11) {
                  return IconButton(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.backspace_outlined),
                  );
                }

                String val = index == 10 ? "0" : "${index + 1}";
                return TextButton(
                  onPressed: () => _onKeyPressed(val),
                  style: TextButton.styleFrom(
                    shape: const CircleBorder(),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: Text(val),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
