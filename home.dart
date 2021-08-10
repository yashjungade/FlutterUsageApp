import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //List of applications
  List<AppUsageInfo> _infos = [];
  //List of colors
  List colors = [Colors.red, Colors.purple, Colors.blue];
  //Total time spent on mobile
  Duration usageSum = Duration(minutes: 1);
  //Appending the application list with all app usages
  void getUsageStats() async {
    try {
      DateTime endDate = new DateTime.now();
      DateTime startDate = endDate.subtract(Duration(hours: 24));
      List<AppUsageInfo> infoList = await AppUsage.getAppUsage(startDate, endDate);
      setState(() {
        usageSum=Duration();
        _infos = infoList;
        _infos.sort((b,a) => a.usage.compareTo(b.usage));
        _infos.removeRange(10, _infos.length);

        _infos.forEach((element) async {
          usageSum+=element.usage;
        });
      });

      //print(usageSum);
      for (var info in infoList) {
        print(info.toString());
      }
    } on AppUsageException catch (exception) {
      print(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Front End
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: Icon(Icons.apps, color: Colors.green,),
          title: const Text('Usage', style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 10,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Total Time Spent on Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                    //Get app usage list by clicking on refresh
                    GestureDetector(child: Icon(Icons.refresh, color: Colors.blue,), onTap: () {
                      getUsageStats();
                      _infos.forEach((element) async {
                        await FirebaseFirestore.instance.collection('Users').doc('Test').update(
                            {
                              element.appName : {'Name': element.appName, 'Duration': element.usage.inMinutes}
                            });
                      });
                    },)
                  ],
                ),
                SizedBox(height: 20,),
                //Donut Chart
                CircleAvatar(radius: 100, backgroundColor: Colors.green, child: Text(
                  "${((usageSum.inMinutes)/60).truncate()} Hours\n${(usageSum.inMinutes)-(((usageSum.inMinutes)/60).truncate())*60} mins",
                textAlign: TextAlign.center,style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),),),
                SizedBox(height: 40,),
                Row(
                    children: [
                      Text('Top 3 Apps killing your time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),),
                    ],
                  ),
                // List of top 3 apps
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 400,
                    child: ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(Icons.circle, color: colors[index]),
                            title: Text(
                                  "${_infos[index].appName.substring(0, 1).toUpperCase()}${_infos[index].appName.substring(1)}"),
                            subtitle: Text(
                                "${((_infos[index].usage.inMinutes)/60).truncate()} hour ${(_infos[index].usage.inMinutes)-(((_infos[index].usage.inMinutes)/60).truncate())*60} mins",
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            trailing: Text("${(100*((_infos[index].usage.inMinutes)/(usageSum.inMinutes))).truncate()}%", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}