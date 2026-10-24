import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api.dart';
import 'branding.dart';
import 'products.dart';
import 'services_app.dart';

Color get brandNavy => appBrand.value.primary;
Color get brandOrange => appBrand.value.accent;
Color get ink => appBrand.value.primary;
const muted = Color(0xFF697382);
const cream = Color(0xFFF5F6FA);
Color get mint =>
    Color.alphaBlend(appBrand.value.accent.withValues(alpha: .1), Colors.white);
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(refreshBrand());
  runApp(DanxaliyeApp());
}

class DanxaliyeApp extends StatefulWidget {
  const DanxaliyeApp({super.key});
  @override
  State<DanxaliyeApp> createState() => _DanxaliyeAppState();
}

class _DanxaliyeAppState extends State<DanxaliyeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refreshBrand());
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppBrand>(
    valueListenable: appBrand,
    builder: (context, brand, child) => MaterialApp(
      title: brand.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandNavy,
          primary: brandNavy,
          surface: Colors.white,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: ink),
          headlineMedium: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ink,
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE0E7E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE0E7E0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: mint,
        ),
      ),
      home: Shell(),
    ),
  );
}

void toast(BuildContext c, Object e) {
  ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
  );
}

Future<void> open(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page));
String initials(String name) =>
    name.split(' ').where((s) => s.isNotEmpty).take(2).map((s) => s[0]).join();
IconData categoryIcon(dynamic id) => switch ((id as num?)?.toInt()) {
  1 => Icons.bolt_rounded,
  2 => Icons.plumbing_rounded,
  3 => Icons.ac_unit_rounded,
  _ => Icons.kitchen_outlined,
};
String localTime(dynamic value) {
  if (value == null) return '';
  final raw = value.toString();
  final d = DateTime.parse(
    raw.endsWith('Z') ? raw : '${raw}Z',
  ).toUtc().add(Duration(hours: 3));
  return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} EAT';
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    api.restore().whenComplete(() {
      if (mounted) {
        setState(() => loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: DanxaliyeBrand(),
      toolbarHeight: 76,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 18),
          child: Chip(
            avatar: Icon(Icons.location_on_outlined, size: 15),
            label: Text(appBrand.value.city, style: TextStyle(fontSize: 11)),
            backgroundColor: cream,
            side: BorderSide.none,
          ),
        ),
      ],
    ),
    body: loading
        ? Center(child: CircularProgressIndicator())
        : switch (tab) {
            0 => ServiceHome(),
            1 => ServiceCatalogScreen(),
            2 => ServiceOrders(),
            4 =>
              appBrand.value.productsEnabled ? ProductCatalog() : ServiceHome(),
            _ => Account(onChanged: () => setState(() {})),
          },
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab == 4 && !appBrand.value.productsEnabled ? 0 : tab,
      onDestinationSelected: (v) => setState(() => tab = v),
      destinations: [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Hoyga'),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          label: 'Adeegyada',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Dalabyada',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Akoonka',
        ),
        if (appBrand.value.productsEnabled)
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Products',
          ),
      ],
    ),
  );
}

class Discover extends StatefulWidget {
  const Discover({super.key});
  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  final search = TextEditingController(), city = TextEditingController();
  int? category;
  List<dynamic> categories = [], pros = [];
  bool busy = true, available = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    city.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await Future.wait([
        api.request('/categories'),
        api.request(
          '/professionals?${Uri(queryParameters: {'q': search.text, 'city': city.text, 'available': '$available', if (category != null) 'category': '$category'}).query}',
        ),
      ]);
      if (mounted) {
        setState(() {
          categories = result[0];
          pros = result[1];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR NEIGHBORHOOD. YOUR EXPERTS.',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                  color: brandNavy,
                ),
              ),
              SizedBox(height: 17),
              Text(
                'A helping hand.\nJust around\nthe corner.',
                style: TextStyle(
                  fontSize: 35,
                  height: 1.12,
                  letterSpacing: -1.3,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Good people. Great work. Right nearby.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              SizedBox(height: 24),
              TextField(
                controller: search,
                onSubmitted: (_) => load(),
                decoration: InputDecoration(
                  hintText: 'What do you need help with?',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: load,
                    icon: Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: city,
                onSubmitted: (_) => load(),
                decoration: InputDecoration(
                  hintText: 'City or neighborhood',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 28),
        Text(
          'What can we help with?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -.6,
          ),
        ),
        SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('All services'),
                  selected: category == null,
                  onSelected: (_) {
                    category = null;
                    load();
                  },
                ),
              ),
              ...categories.map(
                (cat) => Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(categoryIcon(cat['id']), size: 18),
                    label: Text(cat['name']),
                    selected: category == cat['id'],
                    onSelected: (_) {
                      category = cat['id'];
                      load();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 25),
        Text(
          'Meet your local experts',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -.6,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Accepting requests',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          value: available,
          onChanged: (v) {
            available = v;
            load();
          },
        ),
        if (busy)
          Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          ErrorPanel(
            message: 'Could not load professionals. Check your connection.',
            retry: load,
          )
        else if (pros.isEmpty)
          EmptyPanel(
            icon: Icons.search_off,
            title: 'No matches yet',
            message: 'Try another service or neighborhood.',
          )
        else
          ...pros.map((p) => ProCard(pro: Map<String, dynamic>.from(p))),
      ],
    ),
  );
}

class ProCard extends StatelessWidget {
  final Map<String, dynamic> pro;
  final bool showAction;
  const ProCard({super.key, required this.pro, this.showAction = true});
  @override
  Widget build(BuildContext c) => Container(
    margin: EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border.all(color: Color(0xFFE4E9E5)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: mint,
              child: Text(
                initials(pro['name']),
                style: TextStyle(color: brandNavy, fontWeight: FontWeight.w600),
              ),
            ),
            Spacer(),
            StatusBadge(
              pro['acceptingRequests'] ? '● Accepting requests' : 'Unavailable',
            ),
          ],
        ),
        SizedBox(height: 18),
        Text(
          pro['category'],
          style: TextStyle(
            color: brandNavy,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 5),
        Text(
          pro['name'],
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '⌖ ${pro['neighborhood']}, ${pro['city']}',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        SizedBox(height: 14),
        Text(
          '★ ${pro['rating'] ?? 'New'}  (${pro['reviewCount']} reviews)  ·  ${pro['yearsExperience']} years experience',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),
        Row(
          children: [
            Text(
              '\$${pro['hourlyRate']}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(' / hour', style: TextStyle(fontSize: 11, color: muted)),
            Spacer(),
            OutlinedButton(
              onPressed: showAction
                  ? () => open(c, ProfessionalPage(id: pro['id']))
                  : null,
              child: Text('View profile ↗'),
            ),
          ],
        ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  final String text;
  const StatusBadge(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: TextStyle(color: brandNavy, fontSize: 10)),
  );
}

class ProfessionalPage extends StatefulWidget {
  final int id;
  const ProfessionalPage({super.key, required this.id});
  @override
  State<ProfessionalPage> createState() => _ProfessionalPageState();
}

class _ProfessionalPageState extends State<ProfessionalPage> {
  Map<String, dynamic>? pro;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final p = await api.request('/professionals/${widget.id}');
      if (mounted) {
        setState(() => pro = Map<String, dynamic>.from(p));
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Your local expert')),
    body: error != null
        ? ErrorPanel(message: error!, retry: load)
        : pro == null
        ? Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(24),
            children: [
              ProCard(pro: pro!, showAction: false),
              Text(
                'A little about me',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(pro!['bio']),
              SizedBox(height: 20),
              Text(
                'Working hours: ${pro!['startHour']}:00–${pro!['endHour']}:00 EAT',
                style: TextStyle(color: muted),
              ),
              SizedBox(height: 8),
              Text(
                'Profile approved. Qualifications not independently verified.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  if (await ensureLogin(c) && c.mounted) {
                    await open(c, ChatPage(pro: widget.id, name: pro!['name']));
                  }
                },
                icon: Icon(Icons.chat_bubble_outline),
                label: Text('Start a conversation'),
              ),
              SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: pro!['acceptingRequests']
                    ? () async {
                        if (await ensureLogin(c) && c.mounted) {
                          await open(
                            c,
                            ServiceRequestForm(
                              category: {
                                'id': pro!['categoryId'],
                                'name': pro!['category'],
                              },
                            ),
                          );
                        }
                      }
                    : null,
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('Send request to dispatch'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  if (await ensureLogin(c)) {
                    try {
                      await api.request('/favorites/${widget.id}', body: {});
                      if (c.mounted) {
                        toast(c, 'Saved professionals updated.');
                      }
                    } catch (e) {
                      if (c.mounted) {
                        toast(c, e);
                      }
                    }
                  }
                },
                icon: Icon(Icons.favorite_border),
                label: Text('Save / unsave professional'),
              ),
              TextButton(
                onPressed: () async {
                  if (await ensureLogin(c) && c.mounted) {
                    await open(c, ReportPage(pro: widget.id));
                  }
                },
                child: Text('Report or block this professional'),
              ),
              if ('${pro!['phone']}'.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: pro!['phone']));
                    if (c.mounted) {
                      toast(c, 'Phone number copied: ${pro!['phone']}');
                    }
                  },
                  icon: Icon(Icons.phone_outlined),
                  label: Text('Copy phone: ${pro!['phone']}'),
                ),
              SizedBox(height: 24),
              Text(
                'Customer reviews',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              if ((pro!['reviews'] as List).isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'No reviews yet. You could be their first customer.',
                    style: TextStyle(color: muted),
                  ),
                ),
              ...(pro!['reviews'] as List).map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('★ ${r['rating']}/5'),
                  subtitle: Text(r['text']),
                ),
              ),
            ],
          ),
  );
}

Future<bool> ensureLogin(BuildContext c) async {
  if (api.token != null) return true;
  await open(c, AuthPage());
  return api.token != null;
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      confirm = TextEditingController();
  bool register = false, busy = false, terms = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    confirm.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!email.text.trim().contains('@') ||
        password.text.isEmpty ||
        (register &&
            (name.text.trim().isEmpty ||
                name.text.trim().length > 100 ||
                password.text != confirm.text))) {
      setState(
        () => error = 'Enter a valid email, full name and matching passwords.',
      );
      return;
    }
    if (register && !appBrand.value.registrationEnabled) {
      setState(() => error = 'New account registration is currently closed.');
      return;
    }
    if (register && !terms) {
      setState(() => error = 'Accept the service terms to continue.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (register) {
        await api.request(
          '/register',
          body: {
            'name': name.text.trim(),
            'email': email.text.trim(),
            'password': password.text,
            'confirmPassword': confirm.text,
            'terms': terms,
          },
        );
      }
      await api.login(email.text.trim(), password.text);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(),
    body: ListView(
      padding: EdgeInsets.all(28),
      children: [
        DanxaliyeBrand(),
        SizedBox(height: 30),
        Text(
          register ? 'Ku soo biir ${appBrand.value.name}.' : 'Soo dhowow.',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 10),
        Text(appBrand.value.tagline, style: TextStyle(color: muted)),
        SizedBox(height: 30),
        if (register) ...[
          TextField(
            controller: name,
            autofillHints: [AutofillHints.name],
            maxLength: 100,
            decoration: InputDecoration(labelText: 'Magaca oo buuxa'),
          ),
          SizedBox(height: 16),
        ],
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: [AutofillHints.email],
          decoration: InputDecoration(labelText: 'Cinwaanka iimaylka'),
        ),
        SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          autofillHints: [AutofillHints.password],
          decoration: InputDecoration(labelText: 'Furaha sirta'),
        ),
        SizedBox(height: 10),
        if (register) ...[
          TextField(
            controller: confirm,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Confirm password'),
          ),
          SizedBox(height: 12),
          Text(
            '10+ characters, uppercase, lowercase, number and symbol.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: terms,
            onChanged: (v) => setState(() => terms = v ?? false),
            title: Text(
              'I accept the provisional service terms.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${appBrand.value.name} stores account, message and booking data. See the website for terms and privacy.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
        if (error != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(error!, style: TextStyle(color: Colors.red)),
          ),
        SizedBox(height: 20),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(
            busy
                ? 'Fadlan sug…'
                : register
                ? 'Isdiiwaangeli ↗'
                : 'Soo gal ↗',
          ),
        ),
        if (appBrand.value.registrationEnabled || register)
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    register = !register;
                    error = null;
                  }),
            child: Text(
              register ? 'Akoon ma leedahay? Soo gal' : 'Akoon cusub samee',
            ),
          ),
      ],
    ),
  );
}

class BookPage extends StatefulWidget {
  final Map<String, dynamic> pro;
  const BookPage({super.key, required this.pro});
  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  DateTime? date;
  int? hour;
  final desc = TextEditingController(), address = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    desc.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (date == null ||
        hour == null ||
        desc.text.trim().isEmpty ||
        address.text.trim().isEmpty) {
      toast(context, 'Choose a time and fill in the job and address.');
      return;
    }
    setState(() => busy = true);
    try {
      final utc = DateTime.utc(
        date!.year,
        date!.month,
        date!.day,
        hour!,
      ).subtract(Duration(hours: 3));
      await api.request(
        '/appointments',
        body: {
          'professionalId': widget.pro['id'],
          'startUtc': utc.toIso8601String(),
          'description': desc.text.trim(),
          'address': address.text.trim(),
        },
      );
      if (mounted) {
        toast(context, 'Request sent. Awaiting professional confirmation.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        toast(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Book a helping hand')),
    body: ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text(
          widget.pro['name'],
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        Text(
          '${widget.pro['category']} · From \$${widget.pro['hourlyRate']}/hour',
          style: TextStyle(color: muted),
        ),
        SizedBox(height: 25),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: c,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 90)),
            );
            if (d != null) {
              setState(() => date = d);
            }
          },
          icon: Icon(Icons.calendar_today_outlined),
          label: Text(
            date == null
                ? 'Select date'
                : '${date!.day}/${date!.month}/${date!.year}',
          ),
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: hour,
          decoration: InputDecoration(
            labelText: 'Time (East Africa Time, UTC+3)',
          ),
          items: [
            for (
              var h = widget.pro['startHour'] as int;
              h < (widget.pro['endHour'] as int);
              h++
            )
              DropdownMenuItem(
                value: h,
                child: Text('${h.toString().padLeft(2, '0')}:00 — ${h + 1}:00'),
              ),
          ],
          onChanged: (v) => setState(() => hour = v),
        ),
        SizedBox(height: 16),
        TextField(
          controller: desc,
          maxLines: 4,
          maxLength: 2000,
          decoration: InputDecoration(labelText: 'What do you need help with?'),
        ),
        SizedBox(height: 16),
        TextField(
          controller: address,
          maxLength: 300,
          decoration: InputDecoration(labelText: 'Service address'),
        ),
        Text(
          'Your address is shared only with this professional. Pay directly after agreeing the final price. The appointment is reserved after confirmation.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        SizedBox(height: 25),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Sending…' : 'Request appointment ↗'),
        ),
      ],
    ),
  );
}

class Bookings extends StatefulWidget {
  const Bookings({super.key});
  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  List<dynamic>? items;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (api.token == null) return;
    try {
      final list = await api.request('/appointments');
      if (mounted) {
        setState(() {
          items = list;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  Future<void> action(int id, String action, {DateTime? time}) async {
    try {
      await api.request(
        '/appointments/$id/action',
        body: {
          'action': action,
          if (time != null) 'proposedStartUtc': time.toIso8601String(),
        },
      );
      await load();
    } catch (e) {
      if (mounted) {
        toast(context, e);
      }
    }
  }

  Future<void> reschedule(int id) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 10, minute: 0),
    );
    if (t == null || !mounted) return;
    if (t.minute != 0) {
      toast(context, 'Choose a whole hour, such as 10:00.');
      return;
    }
    await action(
      id,
      'reschedule',
      time: DateTime.utc(
        d.year,
        d.month,
        d.day,
        t.hour,
      ).subtract(Duration(hours: 3)),
    );
  }

  Future<void> review(int id) async {
    final text = TextEditingController();
    int rating = 5;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, state) => AlertDialog(
          title: Text('Share your experience'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: rating,
                items: [
                  for (int n = 5; n >= 1; n--)
                    DropdownMenuItem(value: n, child: Text('$n stars')),
                ],
                onChanged: (v) => state(() => rating = v!),
              ),
              TextField(
                controller: text,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Your review'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await api.request(
                    '/reviews',
                    body: {
                      'appointmentId': id,
                      'rating': rating,
                      'text': text.text,
                    },
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    toast(context, 'Thank you for your review.');
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    toast(ctx, e);
                  }
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
    text.dispose();
  }

  @override
  Widget build(BuildContext c) {
    if (api.token == null) {
      return SignInPanel(
        onSignedIn: () => setState(() {
          load();
        }),
      );
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'Your appointments.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Plans made simple. All times shown in EAT.',
            style: TextStyle(color: muted),
          ),
          SizedBox(height: 24),
          if (error != null)
            ErrorPanel(message: error!, retry: load)
          else if (items == null)
            Center(child: CircularProgressIndicator())
          else if (items!.isEmpty)
            EmptyPanel(
              icon: Icons.calendar_month_outlined,
              title: 'Your calendar is clear',
              message: 'Find a local professional to request your first visit.',
            )
          else
            ...items!.map((a) {
              final owner = a['isProfessional'] as bool;
              final status = a['status'];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE4E9E5)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(status),
                    SizedBox(height: 12),
                    Text(
                      a['professional'],
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      localTime(a['startUtc']),
                      style: TextStyle(color: brandNavy, fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    Text(a['description']),
                    Text(
                      a['address'],
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (owner && status == 'Requested')
                          ...['confirm', 'decline'].map(
                            (v) => OutlinedButton(
                              onPressed: () => action(a['id'], v),
                              child: Text(v),
                            ),
                          ),
                        if (status == 'Requested' || status == 'Confirmed')
                          OutlinedButton(
                            onPressed: () => action(a['id'], 'cancel'),
                            child: Text('Cancel'),
                          ),
                        if (owner && status == 'Confirmed')
                          FilledButton(
                            onPressed: () => action(a['id'], 'start'),
                            child: Text('Start work'),
                          ),
                        if (owner && status == 'InProgress')
                          FilledButton(
                            onPressed: () => action(a['id'], 'complete'),
                            child: Text('Complete'),
                          ),
                        if (status == 'Confirmed')
                          OutlinedButton(
                            onPressed: () => reschedule(a['id']),
                            child: Text('Reschedule'),
                          ),
                        if (!owner && status == 'Completed')
                          OutlinedButton(
                            onPressed: () => review(a['id']),
                            child: Text('Write review'),
                          ),
                        TextButton(
                          onPressed: () => open(
                            c,
                            ChatPage(
                              pro: a['professionalId'],
                              customer: owner ? a['customerId'] : null,
                              name: a['professional'],
                            ),
                          ),
                          child: Text('Message ↗'),
                        ),
                      ],
                    ),
                    if (a['proposedStartUtc'] != null) ...[
                      Text(
                        'Proposed: ${localTime(a['proposedStartUtc'])}',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      if (a['proposedById'] != api.me?['id'])
                        TextButton(
                          onPressed: () => action(a['id'], 'accept-time'),
                          child: Text('Accept new time'),
                        ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class Inbox extends StatefulWidget {
  const Inbox({super.key});
  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  List<dynamic>? threads;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (api.token == null) return;
    try {
      final data = await api.request('/inbox');
      if (mounted) {
        setState(() {
          threads = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    if (api.token == null) {
      return SignInPanel(
        onSignedIn: () => setState(() {
          load();
        }),
      );
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text(
            'Let’s talk.',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Great work starts with a conversation.',
            style: TextStyle(color: muted),
          ),
          SizedBox(height: 24),
          if (error != null)
            ErrorPanel(message: error!, retry: load)
          else if (threads == null)
            Center(child: CircularProgressIndicator())
          else if (threads!.isEmpty)
            EmptyPanel(
              icon: Icons.chat_bubble_outline,
              title: 'Say hello',
              message: 'Open a professional profile to start a conversation.',
            )
          else
            ...threads!.map(
              (t) => ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: mint,
                  child: Icon(Icons.chat_bubble_outline, color: brandNavy),
                ),
                title: Text(
                  t['name'] ?? 'Professional #${t['professionalId']}',
                ),
                subtitle: Text(
                  t['text'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await open(
                    c,
                    ChatPage(
                      pro: t['professionalId'],
                      customer: t['customerId'],
                      name: t['name'] ?? 'Conversation',
                    ),
                  );
                  load();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final int pro;
  final String? customer;
  final String name;
  const ChatPage({
    super.key,
    required this.pro,
    this.customer,
    required this.name,
  });
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Timer? refresh;
  final text = TextEditingController();
  List<dynamic>? items;
  bool sending = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
    refresh = Timer.periodic(Duration(seconds: 5), (_) => load());
  }

  @override
  void dispose() {
    refresh?.cancel();
    text.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final data = await api.request(
        '/messages/${widget.pro}${widget.customer == null ? '' : '?customer=${Uri.encodeComponent(widget.customer!)}'}',
      );
      if (mounted) {
        setState(() {
          items = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  Future<void> send() async {
    if (text.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await api.request(
        '/messages/${widget.pro}',
        body: {'text': text.text.trim(), 'customerId': widget.customer},
      );
      text.clear();
      await load();
    } catch (e) {
      if (mounted) {
        toast(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(widget.name),
      actions: [
        IconButton(
          onPressed: load,
          tooltip: 'Refresh messages',
          icon: Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              'Private conversation · Messages refresh automatically',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
          Expanded(
            child: error != null
                ? ErrorPanel(message: error!, retry: load)
                : items == null
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.all(20),
                    children: items!.map((m) {
                      final mine = m['senderId'] == api.me?['id'];
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 290),
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: mine ? mint : cream,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['text']),
                              SizedBox(height: 5),
                              Text(
                                localTime(m['createdUtc']),
                                style: TextStyle(fontSize: 9, color: muted),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      hintText: 'Write a message…',
                      counterText: '',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton.filled(
                  onPressed: sending ? null : send,
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class Account extends StatelessWidget {
  final VoidCallback onChanged;
  const Account({super.key, required this.onChanged});
  @override
  Widget build(BuildContext c) {
    if (api.token == null) return SignInPanel(onSignedIn: onChanged);
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: mint,
          child: Icon(Icons.person_outline, size: 34, color: brandNavy),
        ),
        SizedBox(height: 18),
        Text(
          api.me?['name']?.toString().isNotEmpty == true
              ? api.me!['name']
              : api.me?['email'] ?? 'Your profile',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 30),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your next customer\nis nearby.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Put your skills on the map. Create or update your professional profile.',
                style: TextStyle(color: muted),
              ),
              SizedBox(height: 20),
              FilledButton(
                onPressed: () => open(c, ProfessionalEditor()),
                child: Text('Akoonka xirfadlaha ↗'),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        if (api.me?['isAdmin'] == true)
          ListTile(
            leading: Icon(Icons.settings_outlined, color: brandNavy),
            title: Text('Brand, products & users'),
            subtitle: Text('Open the administration website'),
            onTap: () => open(c, AdminLinkPage()),
          ),
        ListTile(
          leading: Icon(Icons.favorite_border, color: brandNavy),
          title: Text('Xirfadlayaasha la kaydiyay'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => open(c, SavedPage()),
        ),
        ListTile(
          leading: Icon(Icons.notifications_none, color: brandNavy),
          title: Text('Ogeysiisyada'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => open(c, UpdatesPage()),
        ),
        ListTile(
          leading: Icon(Icons.chat_bubble_outline, color: brandNavy),
          title: Text('Fariimaha'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => open(
            c,
            Scaffold(
              appBar: AppBar(title: Text('Fariimaha')),
              body: Inbox(),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.people_outline, color: brandNavy),
          title: Text('Xirfadlayaasha'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => open(
            c,
            Scaffold(
              appBar: AppBar(title: Text('Xirfadlayaasha')),
              body: Discover(),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.event_outlined, color: brandNavy),
          title: Text('Dalabyada'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => open(
            c,
            Scaffold(
              appBar: AppBar(title: Text('Dalabyada')),
              body: ServiceOrders(),
            ),
          ),
        ),
        SizedBox(height: 25),
        Text(
          'Development preview. Payments are arranged directly with professionals. Account verification and production support are not enabled yet.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        ListTile(
          leading: Icon(Icons.block_outlined, color: brandNavy),
          title: Text('Xirfadlayaasha la xannibay'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => open(c, BlocksPage()),
        ),
        SizedBox(height: 30),
        OutlinedButton(
          onPressed: () async {
            await api.logout();
            onChanged();
          },
          child: Text('Ka bax'),
        ),
      ],
    );
  }
}

class ProfessionalEditor extends StatefulWidget {
  const ProfessionalEditor({super.key});
  @override
  State<ProfessionalEditor> createState() => _ProfessionalEditorState();
}

class _ProfessionalEditorState extends State<ProfessionalEditor> {
  final name = TextEditingController(),
      city = TextEditingController(text: appBrand.value.city),
      area = TextEditingController(),
      bio = TextEditingController(),
      phone = TextEditingController(),
      rate = TextEditingController(text: '20'),
      years = TextEditingController(text: '1'),
      start = TextEditingController(text: '8'),
      end = TextEditingController(text: '18');
  List<dynamic> categories = [];
  int? category;
  bool accepting = true, busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await api.request('/professional');
      final cats = await api.request('/categories');
      if (mounted) {
        setState(() {
          categories = cats;
          category =
              data?['categoryId'] ??
              (categories.isEmpty ? null : categories.first['id']);
          if (data != null) {
            name.text = data['name'];
            city.text = data['city'];
            area.text = data['neighborhood'];
            bio.text = data['bio'];
            phone.text = data['phone'];
            rate.text = '${data['hourlyRate']}';
            years.text = '${data['yearsExperience']}';
            start.text = '${data['startHour']}';
            end.text = '${data['endHour']}';
            accepting = data['acceptingRequests'];
          }
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final t in [name, city, area, bio, phone, rate, years, start, end]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() => busy = true);
    try {
      await api.request(
        '/professional',
        body: {
          'name': name.text,
          'categoryId': category,
          'city': city.text,
          'neighborhood': area.text,
          'bio': bio.text,
          'phone': phone.text,
          'hourlyRate': double.tryParse(rate.text) ?? -1,
          'yearsExperience': int.tryParse(years.text) ?? -1,
          'startHour': int.tryParse(start.text) ?? -1,
          'endHour': int.tryParse(end.text) ?? -1,
          'acceptingRequests': accepting,
        },
      );
      if (mounted) {
        toast(context, 'Submitted for administrator approval.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        toast(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Widget field(
    String label,
    TextEditingController t, {
    bool number = false,
    int lines = 1,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: t,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    ),
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Your professional profile')),
    body: busy
        ? Center(child: CircularProgressIndicator())
        : error != null
        ? ErrorPanel(message: error!, retry: load)
        : ListView(
            padding: EdgeInsets.all(24),
            children: [
              Text(
                'Great work starts with you.',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 20),
              field('Name or business name', name),
              DropdownButtonFormField<int>(
                initialValue: category,
                decoration: InputDecoration(labelText: 'Your specialty'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => category = v,
              ),
              SizedBox(height: 16),
              field('City', city),
              field('Neighborhood', area),
              field('About your services', bio, lines: 4),
              field('Public phone (optional)', phone),
              Text(
                'Entering a phone number makes it publicly visible.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              SizedBox(height: 16),
              field('Starting hourly rate (USD)', rate, number: true),
              field('Years of experience', years, number: true),
              field('Start hour (0–23, EAT)', start, number: true),
              field('End hour (1–24, EAT)', end, number: true),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Accepting requests'),
                value: accepting,
                onChanged: (v) => setState(() => accepting = v),
              ),
              Text(
                'Profile changes require administrator approval before publication.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              SizedBox(height: 20),
              FilledButton(
                onPressed: save,
                child: Text('Submit for approval ↗'),
              ),
            ],
          ),
  );
}

class EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext c) => Container(
    padding: EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: cream,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 42, color: brandNavy),
        SizedBox(height: 18),
        Text(
          title,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ],
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const ErrorPanel({super.key, required this.message, required this.retry});
  @override
  Widget build(BuildContext c) => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: muted),
          SizedBox(height: 15),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 15),
          OutlinedButton(onPressed: retry, child: Text('Try again')),
        ],
      ),
    ),
  );
}

class SignInPanel extends StatelessWidget {
  final VoidCallback onSignedIn;
  const SignInPanel({super.key, required this.onSignedIn});
  @override
  Widget build(BuildContext c) => Center(
    child: Padding(
      padding: EdgeInsets.all(35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waving_hand_outlined, color: brandNavy, size: 50),
          SizedBox(height: 20),
          Text(
            'Ku soo dhowow ${appBrand.value.name}.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Soo gal si aad u dalbato adeeg, ula hadasho xirfadle, oo aad ula socoto dalabkaaga.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          SizedBox(height: 25),
          FilledButton(
            onPressed: () async {
              await open(c, AuthPage());
              onSignedIn();
            },
            child: Text('Soo gal ama isdiiwaangeli ↗'),
          ),
        ],
      ),
    ),
  );
}

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});
  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<dynamic>? items;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await api.request('/favorites');
      if (mounted) {
        setState(() {
          items = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Xirfadlayaasha la kaydiyay')),
    body: error != null
        ? ErrorPanel(message: error!, retry: load)
        : items == null
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: EdgeInsets.all(20),
              children: items!.isEmpty
                  ? [
                      EmptyPanel(
                        icon: Icons.favorite_border,
                        title: 'Your shortlist starts here',
                        message:
                            'Save professionals from their profiles to find them again.',
                      ),
                    ]
                  : items!
                        .map((p) => ProCard(pro: Map<String, dynamic>.from(p)))
                        .toList(),
            ),
          ),
  );
}

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});
  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  List<dynamic>? items;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await api.request('/notifications');
      if (mounted) {
        setState(() {
          items = result;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text('Ogeysiisyada'),
      actions: [
        IconButton(
          tooltip: 'Mark all as read',
          onPressed: () async {
            try {
              await api.request('/notifications/read', body: {});
              await load();
            } catch (e) {
              if (c.mounted) {
                toast(c, e);
              }
            }
          },
          icon: Icon(Icons.done_all),
        ),
      ],
    ),
    body: error != null
        ? ErrorPanel(message: error!, retry: load)
        : items == null
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: EdgeInsets.all(20),
              children: items!.isEmpty
                  ? [
                      EmptyPanel(
                        icon: Icons.notifications_none,
                        title: 'You’re all caught up',
                        message:
                            'Messages and appointment changes will appear here.',
                      ),
                    ]
                  : items!
                        .map(
                          (n) => ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                            leading: Icon(
                              n['read']
                                  ? Icons.notifications_none
                                  : Icons.notifications_active_outlined,
                              color: brandNavy,
                            ),
                            title: Text(n['text']),
                            subtitle: Text(localTime(n['createdUtc'])),
                          ),
                        )
                        .toList(),
            ),
          ),
  );
}

class ReportPage extends StatefulWidget {
  final int pro;
  const ReportPage({super.key, required this.pro});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final reason = TextEditingController();
  bool block = false, busy = false;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Report a concern')),
    body: ListView(
      padding: EdgeInsets.all(24),
      children: [
        Text(
          'Help keep the neighborhood safe.',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 20),
        TextField(
          controller: reason,
          maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(labelText: 'What happened?'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Also block messages'),
          value: block,
          onChanged: (v) => setState(() => block = v),
        ),
        SizedBox(height: 20),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  if (reason.text.trim().isEmpty) {
                    toast(c, 'Enter a reason.');
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    await api.request(
                      '/report/${widget.pro}',
                      body: {'reason': reason.text},
                    );
                    if (block) {
                      await api.request(
                        '/block/${widget.pro}',
                        body: {'blocked': true},
                      );
                    }
                    if (c.mounted) {
                      toast(c, 'Your report was sent to the administrator.');
                      Navigator.pop(c);
                    }
                  } catch (e) {
                    if (c.mounted) {
                      toast(c, e);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => busy = false);
                    }
                  }
                },
          child: Text('Send report'),
        ),
      ],
    ),
  );
}

class BlocksPage extends StatefulWidget {
  const BlocksPage({super.key});
  @override
  State<BlocksPage> createState() => _BlocksPageState();
}

class _BlocksPageState extends State<BlocksPage> {
  List<dynamic>? items;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await api.request('/blocks');
      if (mounted) {
        setState(() {
          items = data;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text('Xirfadlayaasha la xannibay')),
    body: error != null
        ? ErrorPanel(message: error!, retry: load)
        : items == null
        ? Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.all(20),
            children: items!.isEmpty
                ? [
                    EmptyPanel(
                      icon: Icons.block_outlined,
                      title: 'No blocked accounts',
                      message:
                          'You can block messages from a professional’s profile.',
                    ),
                  ]
                : items!
                      .map(
                        (b) => ListTile(
                          title: Text(b['name']),
                          trailing: TextButton(
                            onPressed: () async {
                              try {
                                await api.request(
                                  '/block/${b['id']}',
                                  body: {'blocked': false},
                                );
                                await load();
                              } catch (e) {
                                if (c.mounted) {
                                  toast(c, e);
                                }
                              }
                            },
                            child: Text('Unblock'),
                          ),
                        ),
                      )
                      .toList(),
          ),
  );
}
