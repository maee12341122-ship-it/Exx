class FastAppLogo extends StatelessWidget {
  const FastAppLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // خلفية سوداء رمادية فخمة
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber, width: 2), // إطار ذهبي
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.flash_on, // أيقونة البرق للدلالة على السرعة الفائقة
            size: 50,
            color: Colors.amber,
          ),
          SizedBox(height: 5),
          Text(
            'FAST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

