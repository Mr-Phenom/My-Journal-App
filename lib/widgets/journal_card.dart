import 'package:flutter/material.dart';

class JournalCard extends StatefulWidget {
  final String title;
  final String snippet;
  final String date;
  final IconData moodIcon;
  final VoidCallback onTap;
  final Function(Offset) onLongPress;

  const JournalCard({
    super.key,
    required this.title,
    required this.snippet,
    required this.date,
    required this.moodIcon,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends State<JournalCard> {
  //to store position of the card
  Offset _tapPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        //captureing the touch position before long press
        onTapDown: (details) {
          _tapPosition = details.globalPosition;
        },
        onLongPress: () {
          widget.onLongPress(_tapPosition);
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 16),
                  Icon(
                    widget.moodIcon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                widget.snippet,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 7,
                overflow: TextOverflow.fade,
              ),

              Spacer(),
              Text(widget.date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
