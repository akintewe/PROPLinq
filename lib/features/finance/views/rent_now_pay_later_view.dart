import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'complete_kyc_view.dart';

class RentNowPayLaterView extends StatefulWidget {
  const RentNowPayLaterView({super.key});

  @override
  State<RentNowPayLaterView> createState() => _RentNowPayLaterViewState();
}

class _RentNowPayLaterViewState extends State<RentNowPayLaterView> {
  final List<String> _whatYouNeed = [
    'BVN – Bank Verification Number',
    'NIN – National Identification Number',
    'Utility Bill',
    '3-6 months bank statement',
  ];

  final List<String> _whatMakesEligible = [
    'Employed or self-employed with verifiable monthly income',
    'Receive income through a bank account',
    'Pass a basic credit check',
    'Agree to automatic monthly repayments',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and subtitle
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Rent now-pay later',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color.fromRGBO(56, 56, 56, 1),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        'Secure your next home today and pay in flexible installments.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                  
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 203,
                              height: 155,
                              child: SvgPicture.asset(
                                'assets/images/OBJECTS.svg',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 203,
                                    height: 155,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF426DC2),
                                      borderRadius: BorderRadius.circular(60),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                      
                    const SizedBox(height: 40),
                    
                    // What you'll need section
                    const Text(
                      'What you\'ll need',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    ..._whatYouNeed.map((item) => _buildChecklistItem(item)),
                    
                    const SizedBox(height: 32),
                    
                    // What makes you eligible section
                    const Text(
                      'What makes you eligible?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    ..._whatMakesEligible.map((item) => _buildChecklistItem(item)),
                    
                    const SizedBox(height: 32),
                    
                    // Info note
                    Container(
                      
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(241, 250, 253, 1),
                        borderRadius: BorderRadius.circular(100),
                       
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/information.svg',
                            width: 20,
                            height: 21,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'If you are not eligible, you will receive a refund within 14 working days',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF426DC2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-1.0, -0.02),
              end: Alignment(1.0, 0.02),
              stops: [0.0113, 0.4555, 1.1245],
              colors: [
                Color(0xFF426DC2),
                Color(0xFF75CFEA),
                Color.fromRGBO(51, 204, 153, 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CompleteKycView(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Proceed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 21,
            margin: const EdgeInsets.only(top: 2),
            child: SvgPicture.asset(
              'assets/icons/ph_seal-check-fill.svg',
              width: 20,
              height: 21,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 