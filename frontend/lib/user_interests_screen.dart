import 'package:flutter/material.dart';
import 'package:frontend/core/models/interest.dart';
import 'package:frontend/components/user_interest_chip.dart';
import 'package:frontend/core/services/api_services.dart';
import 'package:frontend/core/exceptions/api_exception.dart';

class UserInterestsScreen extends StatefulWidget {
  const UserInterestsScreen({super.key});

  @override
  _UserInterestsScreenState createState() => _UserInterestsScreenState();
}

class _UserInterestsScreenState extends State<UserInterestsScreen> {
  List<Interest> allInterests = [];
  List<Interest> userInterests = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchInterests();
  }

  Future<void> fetchInterests() async {
    try {
      final interests = await ApiServices.getAllInterests();
      final userInterests = await ApiServices.getUserInterests();
      setState(() {
        allInterests = interests;
        this.userInterests = userInterests;
        isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unknown error occurred';
        isLoading = false;
      });
    }
  }

  bool isInterestSelected(Interest interest) {
    return userInterests.any((userInterest) => userInterest.id == interest.id);
  }

  Future<void> toggleInterest(Interest interest) async {
    bool isSelected = isInterestSelected(interest);

    setState(() {
      if (isSelected) {
        userInterests.removeWhere((userInterest) => userInterest.id == interest.id);
      } else {
        userInterests.add(interest);
      }
    });

    try {
      if (isSelected) {
        await ApiServices.removeUserInterest(interest.id);
      } else {
        await ApiServices.addUserInterest(interest.id);
      }
    } on ApiException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unknown error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Centres d\'intérêts'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Centres d\'intérêts'),
        ),
        body: Center(child: Text(errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centres d\'intérêts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Wrap(
          spacing: 10.0,
          runSpacing: 5.0,
          alignment: WrapAlignment.start,
          children: allInterests.map((interest) {
            bool isSelected = isInterestSelected(interest);
            return UserInterestChip(
              interest: interest,
              isSelected: isSelected,
              onSelected: toggleInterest,
            );
          }).toList(),
        ),
      ),
    );
  }
}
