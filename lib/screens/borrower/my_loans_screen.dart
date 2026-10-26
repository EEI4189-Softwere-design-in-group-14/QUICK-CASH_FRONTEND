import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'loan_details_screen.dart';

class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});
  @override State<MyLoansScreen> createState() => _MyLoansScreenState();
}
class _MyLoansScreenState extends State<MyLoansScreen> {
  static const green=Color(0xFF168B62);
  final api=ApiService();
  bool loading=true;
  String? error;
  List<Map<String,dynamic>> loans=[];
  @override void initState(){super.initState(); load();}
  Future<void> load() async {
    setState((){loading=true;error=null;});
    try {
      final result=await api.getMyLoans();
      if(!mounted)return;
      setState(()=>loans=result.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList());
    } on ApiException catch(e){if(mounted)setState(()=>error=e.message);}
    catch(_){if(mounted)setState(()=>error='Could not load loans. Please try again.');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  String money(dynamic v){final n=double.tryParse(v?.toString()??'');return n==null?'—':'LKR ${n.toStringAsFixed(2)}';}
  @override void dispose(){api.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF5FAF7),
    appBar:AppBar(title:const Text('My Loans'),backgroundColor:green,foregroundColor:Colors.white),
    body:RefreshIndicator(onRefresh:load,child:loading
      ? const ListView(children:[SizedBox(height:220),Center(child:CircularProgressIndicator())])
      : error!=null
        ? ListView(padding:const EdgeInsets.all(24),children:[const SizedBox(height:100),Text(error!,textAlign:TextAlign.center),TextButton(onPressed:load,child:const Text('Try again'))])
        : loans.isEmpty
          ? const ListView(padding:EdgeInsets.all(24),children:[SizedBox(height:100),Icon(Icons.account_balance_wallet_outlined,size:54,color:green),SizedBox(height:16),Text('No loans yet',textAlign:TextAlign.center,style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text('Your loan applications will appear here.',textAlign:TextAlign.center)])
          : ListView.separated(padding:const EdgeInsets.all(16),itemCount:loans.length,separatorBuilder:(_,__)=>const SizedBox(height:12),itemBuilder:(context,i){
              final loan=loans[i];final status=loan['status']?.toString()??'UNKNOWN';
              return Card(color:Colors.white,elevation:0,child:ListTile(
                leading:const CircleAvatar(backgroundColor:Color(0xFFE5F4EC),child:Icon(Icons.account_balance_wallet_outlined,color:green)),
                title:Text(loan['loanCode']?.toString()??'Loan',style:const TextStyle(fontWeight:FontWeight.bold)),
                subtitle:Text('Requested: ${money(loan['requestedAmount'])}\nPurpose: ${loan['purpose']??'Not specified'}\nOutstanding: ${money(loan['outstandingBalance'])}'),
                isThreeLine:true,
                trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(status,style:const TextStyle(color:green,fontWeight:FontWeight.bold,fontSize:11)),const Icon(Icons.chevron_right,color:green)]),
                onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LoanDetailsScreen(loan:loan))),
              ));
            })),
  );
}
