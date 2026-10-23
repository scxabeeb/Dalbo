import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'main.dart';

class DanxaliyeBrand extends StatelessWidget {
  const DanxaliyeBrand({super.key});
  @override
  Widget build(BuildContext c) => Image.asset('assets/brand/danxaliye-logo.png',width:120,height:60,fit:BoxFit.contain,semanticLabel:'DANXALIYE — Baahidaada, Xalkeeda.');
}

IconData serviceIcon(String name) => switch (name) {
  'Gaadiid Dalbo' => Icons.directions_car_outlined,
  'Bajaaj Dalbo' => Icons.electric_rickshaw_outlined,
  'Koronto-yaqaan' => Icons.bolt_rounded,
  'Tuubiiste' => Icons.water_drop_outlined,
  'Alxanle' => Icons.local_fire_department_outlined,
  'Rinjiile' => Icons.format_paint_outlined,
  'AC & Qaboojiye' => Icons.ac_unit_rounded,
  'Nijaar' => Icons.carpenter_outlined,
  'Solar' => Icons.wb_sunny_outlined,
  'Nadaafad' => Icons.auto_awesome_outlined,
  'Mechanic' => Icons.build_outlined,
  'CCTV & Amni' => Icons.videocam_outlined,
  'Electronics' => Icons.monitor_outlined,
  'Rarid & Guuritaan' => Icons.local_shipping_outlined,
  'Delivery' => Icons.inventory_2_outlined,
  'Dhirayn & Beer' => Icons.eco_outlined,
  _ => Icons.home_repair_service_outlined,
};

class ServiceIcon extends StatelessWidget {
  final String name;
  const ServiceIcon(this.name, {super.key});
  @override
  Widget build(BuildContext c) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: mint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(serviceIcon(name), color: const Color(0xFFB84A00), size: 23),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ink,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              action!,
              style: const TextStyle(color: Color(0xFFB84A00), fontSize: 11),
            ),
          ),
      ],
    ),
  );
}

class ServicesGrid extends StatelessWidget {
  final List<dynamic> categories;
  final Future<void> Function()? onReturn;
  final bool home;
  const ServicesGrid(this.categories, {super.key, this.onReturn,this.home=false});
  @override
  Widget build(BuildContext c) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: home || MediaQuery.sizeOf(c).width > 650 ? 4 : 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 112,
    ),
    itemCount: categories.length+(home?1:0),
    itemBuilder: (c, i) {
      if(home&&i==categories.length){return Material(color:Colors.white,borderRadius:BorderRadius.circular(14),child:InkWell(borderRadius:BorderRadius.circular(14),onTap:()=>open(c,Scaffold(appBar:AppBar(title:const Text('16 Adeeg')),body:const ServiceCatalogScreen())),child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.grid_view_outlined,color:brandNavy,size:29),SizedBox(height:12),Text('Dhammaan',style:TextStyle(fontSize:10,color:ink,fontWeight:FontWeight.w600))])));}
      final cat = Map<String, dynamic>.from(categories[i]);
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            if (await ensureLogin(c) && c.mounted) {
              await open(c, ServiceRequestForm(category: cat));
              await onReturn?.call();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEAECF2)),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ServiceIcon(cat['name']),
                const SizedBox(height: 9),
                Text(
                  cat['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ServiceHome extends StatefulWidget {
  const ServiceHome({super.key});
  @override
  State<ServiceHome> createState() => _ServiceHomeState();
}

class _ServiceHomeState extends State<ServiceHome> {
  List<dynamic>? categories;
  List<dynamic> orders = [];
  String? error;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final cats = await api.request('/categories');
      final requests = api.token == null
          ? []
          : await api.request('/service-requests');
      if (mounted) {
        setState(() {
          categories = cats;
          orders = (requests as List)
              .where((r) => !['Completed', 'Cancelled'].contains(r['status']))
              .take(3)
              .toList();
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
  Widget build(BuildContext c) => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const Text(
          '⌖ Garowe, Puntland',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 8),
        const Text(
          'Maxaad u baahan tahay\nmaanta?',
          style: TextStyle(
            fontSize: 28,
            height: 1.15,
            letterSpacing: -.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: search,
          onSubmitted: (q) => open(
            c,
            Scaffold(
              appBar: AppBar(title: const Text('Adeegyada')),
              body: ServiceCatalogScreen(initialQuery: q),
            ),
          ),
          decoration: InputDecoration(
            hintText: 'Raadi adeeg… (tusaale: Tuubiiste)',
            hintStyle: const TextStyle(fontSize: 12),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: IconButton(
              onPressed: () => open(
                c,
                Scaffold(
                  appBar: AppBar(title: const Text('Adeegyada')),
                  body: ServiceCatalogScreen(initialQuery: search.text),
                ),
              ),
              icon: const Icon(Icons.arrow_forward, size: 19),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: brandNavy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -5,
                top: 0,
                child: Icon(
                  Icons.home_repair_service_outlined,
                  color: brandOrange.withValues(alpha: .7),
                  size: 84,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '16 ADEEG · HAL APP',
                    style: TextStyle(
                      color: Color(0xFFFFD4B6),
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.only(right: 70),
                    child: Text(
                      'Farsamoyaqaan\nalbaabkaaga\nkuugu yimaada.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: brandNavy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                    ),
                    onPressed: () => open(
                      c,
                      Scaffold(
                        appBar: AppBar(title: const Text('16 Adeeg')),
                        body: const ServiceCatalogScreen(),
                      ),
                    ),
                    child: const Text(
                      'Dalbo hadda ↗',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(
          'Adeegyada ugu badan',
          action: 'Dhammaan',
          onTap: () => open(
            c,
            Scaffold(
              appBar: AppBar(title: const Text('16 Adeeg')),
              body: const ServiceCatalogScreen(),
            ),
          ),
        ),
        if (error != null)
          ErrorPanel(message: error!, retry: load)
        else if (categories == null)
          const Center(child: CircularProgressIndicator())
        else
          ServicesGrid(categories!.where((c)=>['Gaadiid Dalbo','Bajaaj Dalbo','Koronto-yaqaan','Tuubiiste','AC & Qaboojiye','Nadaafad','Mechanic'].contains(c['name'])).toList(), onReturn: load,home:true),
        const SizedBox(height: 25),
        SectionTitle(
          'Dalabkaaga socda',
          action: 'Dhammaan',
          onTap: () => open(
            c,
            Scaffold(
              appBar: AppBar(title: const Text('Dalabyada')),
              body: const ServiceOrders(),
            ),
          ),
        ),
        if (orders.isEmpty)
          const EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'Dalab cusub diyaar ma u tahay?',
            message: 'Dooro adeegga aad u baahan tahay si aad u bilowdo.',
          )
        else
          ...orders.map((r) => RequestCard(r, onReturn: load)),
      ],
    ),
  );
}

class ServiceCatalogScreen extends StatefulWidget {
  final String initialQuery;
  const ServiceCatalogScreen({super.key, this.initialQuery = ''});
  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  List<dynamic>? categories;
  String group = 'Dhammaan', query = '';
  String? error;
  late final TextEditingController search;
  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    search = TextEditingController(text: query);
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await api.request('/categories');
      if (mounted) {
        setState(() {
          categories = result;
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
    final filtered = categories
        ?.where(
          (x) =>
              (group == 'Dhammaan' || x['group'] == group) &&
              ('${x['name']} ${x['description']}'.toLowerCase().contains(
                query.toLowerCase(),
              )),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: brandNavy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '16 Adeeg',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Hal meel ka hel adeeg kasta',
                style: TextStyle(color: Color(0xFFCFD3E3), fontSize: 12),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Dhammaan', 'Gaadiid', 'Guriga', 'Farsamo']
                      .map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              g,
                              style: TextStyle(
                                color: group == g ? Colors.white : brandNavy,
                                fontSize: 11,
                              ),
                            ),
                            selected: group == g,
                            selectedColor: const Color(0xFFB64B00),
                            onSelected: (_) => setState(() => group = g),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: search,
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Raadi adeeg…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 20),
        if (error != null)
          ErrorPanel(message: error!, retry: load)
        else if (filtered == null)
          const Center(child: CircularProgressIndicator())
        else if (filtered.isEmpty)
          const EmptyPanel(
            icon: Icons.search_off,
            title: 'Adeeg lama helin',
            message: 'Raadi magac kale ama dooro Dhammaan.',
          )
        else
          ServicesGrid(filtered),
        const SizedBox(height: 20),
        const Text(
          'Ma heli weyday? Doorasho kale raadi ama eeg xirfadlayaasha qaybta Akoonka.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }
}

class ServiceRequestForm extends StatefulWidget {
  final Map<String, dynamic> category;
  final Map<String, dynamic>? existing;
  const ServiceRequestForm({super.key, required this.category, this.existing});
  @override
  State<ServiceRequestForm> createState() => _ServiceRequestFormState();
}

class _ServiceRequestFormState extends State<ServiceRequestForm> {
  final description = TextEditingController(),
      address = TextEditingController(),
      city = TextEditingController(text: 'Garowe');
  String when = 'Now', payment = 'MobileMoney';
  Uint8List? photo;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      description.text = e['description'];
      address.text = e['address'];
      city.text = e['city'];
      when = e['when'];
      payment = e['paymentPreference'];
    }
  }

  @override
  void dispose() {
    description.dispose();
    address.dispose();
    city.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (image == null) return;
      final data = await image.readAsBytes();
      if (data.length > 3 * 1024 * 1024) {
        if (mounted) {
          toast(context, 'Sawirku waa inuu ka yar yahay 3 MB.');
        }
        return;
      }
      if (mounted) {
        setState(() => photo = data);
      }
    } catch (e) {
      if (mounted) {
        toast(context, e);
      }
    }
  }

  Future<void> submit() async {
    if (description.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        city.text.trim().isEmpty) {
      toast(context, 'Buuxi sharaxaadda, magaalada iyo cinwaanka.');
      return;
    }
    setState(() => busy = true);
    try {
      final editing = widget.existing != null;
      final result = await api.request(
        editing
            ? '/service-requests/${widget.existing!['id']}/edit'
            : '/service-requests',
        body: {
          'categoryId': widget.category['id'],
          'description': description.text.trim(),
          'address': address.text.trim(),
          'city': city.text.trim(),
          'when': when,
          'paymentPreference': payment,
          if (photo != null) 'photoBase64': base64Encode(photo!),
        },
      );
      if (mounted) {
        if (editing) {
          Navigator.pop(context);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => ServiceTracking(id: result['id']),
            ),
          );
        }
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

  Widget options(
    String title,
    List<(String, String)> values,
    String selected,
    void Function(String) change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Row(
        children: values
            .map(
              (v) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    showCheckmark: false,
                    selected: selected == v.$1,
                    onSelected: busy ? null : (_) => change(v.$1),
                    label: Center(
                      child: Text(
                        v.$2,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected == v.$1 ? Colors.white : brandNavy,
                        ),
                      ),
                    ),
                    selectedColor: brandNavy,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Samee Dalab',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: brandNavy,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              ServiceIcon(widget.category['name']),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.category['description'],
                      style: const TextStyle(
                        color: Color(0xFFD5D8E6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: description,
          maxLength: 2000,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Sharax ciladda',
            hintText: 'Faahfaahin ka bixi waxa aad u baahan tahay…',
          ),
        ),
        if (widget.existing == null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: busy ? null : pick,
              icon: const Icon(Icons.add_a_photo_outlined, size: 17),
              label: Text(photo == null ? 'Ku dar sawir' : 'Beddel sawirka'),
            ),
          ),
        if (photo != null)
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    photo!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 10,
                child: IconButton.filled(
                  onPressed: () => setState(() => photo = null),
                  icon: const Icon(Icons.close, size: 17),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        const Text(
          'Goobta',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: city,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Magaalada'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: address,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Xaafadda iyo cinwaanka',
          ),
        ),
        const SizedBox(height: 16),
        options(
          'Goorma?',
          [('Now', 'Hadda'), ('Today', 'Maanta'), ('Tomorrow', 'Berri')],
          when,
          (v) => setState(() => when = v),
        ),
        const SizedBox(height: 22),
        options(
          'Habka lacag bixinta',
          [('MobileMoney', 'Mobile Money'), ('Cash', 'Lacag caddaan')],
          payment,
          (v) => setState(() => payment = v),
        ),
        const SizedBox(height: 16),
        const Text(
          'Doorbid keliya. Lacag app-ka lagama qaadayo; qiimaha la heshiis xirfadlaha.',
          style: TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 25),
        const Divider(),
        Row(
          children: [
            const Expanded(
              child: Text('Qiimaha booqashada', style: TextStyle(fontSize: 12)),
            ),
            Text(
              widget.category['visitFee'] == null
                  ? 'Waa la xaqiijinayaa'
                  : '\$${widget.category['visitFee']} USD',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B0B),
            foregroundColor: const Color(0xFF192244),
          ),
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Fadlan sug…' : 'Xaqiiji Dalabka ↗'),
        ),
        const SizedBox(height: 12),
        const Text(
          '“Hadda” ma dammaanad qaado imaansho degdeg ah. Xirfadle ayaa marka hore laguu xilsaarayaa.',
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    ),
  );
}

class ServiceOrders extends StatefulWidget {
  const ServiceOrders({super.key});
  @override
  State<ServiceOrders> createState() => _ServiceOrdersState();
}

class _ServiceOrdersState extends State<ServiceOrders> {
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
      final result = await api.request('/service-requests');
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
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Dalabyadaada',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          const Text(
            'La soco tallaabo kasta.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 23),
          if (error != null)
            ErrorPanel(message: error!, retry: load)
          else if (items == null)
            const Center(child: CircularProgressIndicator())
          else if (items!.isEmpty)
            const EmptyPanel(
              icon: Icons.receipt_long_outlined,
              title: 'Weli dalab ma samayn',
              message: 'Ka dooro adeegga qaybta Adeegyada.',
            )
          else
            ...items!.map((r) => RequestCard(r, onReturn: load)),
        ],
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final dynamic item;
  final Future<void> Function()? onReturn;
  const RequestCard(this.item, {super.key, this.onReturn});
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEAECF2)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(13),
      leading: ServiceIcon(item['category']),
      title: Text(
        '${item['category']} · #${item['id']}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          item['statusLabel'],
          style: const TextStyle(color: muted, fontSize: 11),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 17),
      onTap: () async {
        await open(c, ServiceTracking(id: item['id']));
        await onReturn?.call();
      },
    ),
  );
}

class ServiceTracking extends StatefulWidget {
  final int id;
  const ServiceTracking({super.key, required this.id});
  @override
  State<ServiceTracking> createState() => _ServiceTrackingState();
}

class _ServiceTrackingState extends State<ServiceTracking> {
  Map<String, dynamic>? item;
  String? error;
  Timer? timer;
  Uint8List? photo;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => load());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final result = await api.request('/service-requests/${widget.id}');
      if (mounted) {
        setState(() {
          item = Map<String, dynamic>.from(result);
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    }
  }

  Future<void> act(String action) async {
    setState(() => busy = true);
    try {
      await api.request(
        '/service-requests/${widget.id}/action',
        body: {'action': action},
      );
      await load();
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

  Future<void> showPhoto() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Api.base}/api/service-requests/${widget.id}/photo'),
            headers: {'Authorization': 'Bearer ${api.token}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(
          'Sawirka lama heli karo. Dib u soo gal haddii loo baahdo.',
        );
      }
      if (mounted) {
        setState(() => photo = response.bodyBytes);
      }
    } catch (e) {
      if (mounted) {
        toast(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('La soco Dalabka', style: TextStyle(fontSize: 18)),
      actions: [
        IconButton(
          onPressed: load,
          tooltip: 'Cusboonaysii',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: error != null
        ? ErrorPanel(message: error!, retry: load)
        : item == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ServiceIcon(item!['category']),
                    const SizedBox(height: 15),
                    Text(
                      'Dalab #${widget.id} · ${item!['category']}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      item!['statusLabel'],
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Waqtiga imaanshaha weli lama xaqiijin. Xaaladdu si toos ah ayay u cusboonaanaysaa.',
                      style: TextStyle(fontSize: 10, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (item!['professional'] != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: mint,
                    child: Text(
                      initials(item!['professional']),
                      style: const TextStyle(color: brandNavy),
                    ),
                  ),
                  title: Text(
                    item!['professional'],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Xirfadle laguu xilsaaray',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                Wrap(
                  spacing: 9,
                  children: [
                    if ('${item!['phone'] ?? ''}'.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final launched = await launchUrl(
                              Uri(scheme: 'tel', path: item!['phone']),
                            );
                            if (!launched && c.mounted) {
                              toast(
                                c,
                                'Lambarka lama furi karo: ${item!['phone']}',
                              );
                            }
                          } catch (e) {
                            if (c.mounted) {
                              toast(c, e);
                            }
                          }
                        },
                        icon: const Icon(Icons.phone_outlined, size: 17),
                        label: const Text('Wac'),
                      ),
                    FilledButton.icon(
                      onPressed: () => open(
                        c,
                        ChatPage(
                          pro: item!['professionalId'],
                          name: item!['professional'],
                          customer: item!['isProfessional']
                              ? item!['customerId']
                              : null,
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 17),
                      label: const Text('Fariin'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ] else
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Waxaan raadineynaa xirfadle. Marka la kuu xilsaaro, magaciisa iyo xiriirkiisa halkan ayay ka muuqanayaan.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ...(item!['events'] as List).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 23),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: brandNavy,
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e['label'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              localTime(e['createdUtc']),
                              style: const TextStyle(
                                fontSize: 10,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Text(item!['description'], style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Text(
                '⌖ ${item!['city']} · ${item!['address']}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              Text(
                'Goorma: ${switch (item!['when']) {
                  'Now' => 'Hadda',
                  'Today' => 'Maanta',
                  _ => 'Berri',
                }}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
              Text(
                'Lacag bixinta: ${item!['paymentPreference'] == 'Cash' ? 'Lacag caddaan' : 'Mobile Money'} (doorbid keliya)',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
              if (item!['hasPhoto'])
                TextButton.icon(
                  onPressed: showPhoto,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Eeg sawirka ciladda'),
                ),
              if (photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(photo!),
                ),
              const SizedBox(height: 20),
              if (!item!['isProfessional'] &&
                  ['Received', 'Assigned'].contains(item!['status']))
                OutlinedButton(
                  onPressed: () async {
                    final cats = await api.request('/categories');
                    final category = (cats as List)
                        .where((c) => c['id'] == item!['categoryId'])
                        .firstOrNull;
                    if (category != null && c.mounted) {
                      await open(
                        c,
                        ServiceRequestForm(
                          category: Map<String, dynamic>.from(category),
                          existing: item,
                        ),
                      );
                      load();
                    }
                  },
                  child: const Text('Beddel dalabka'),
                ),
              if (item!['isProfessional']) ...[
                if (item!['status'] == 'Assigned')
                  FilledButton(
                    onPressed: busy ? null : () => act('depart'),
                    child: const Text('Waan soo socdaa'),
                  ),
                if (item!['status'] == 'OnTheWay')
                  FilledButton(
                    onPressed: busy ? null : () => act('start'),
                    child: const Text('Bilow shaqada'),
                  ),
                if (item!['status'] == 'InProgress')
                  FilledButton(
                    onPressed: busy ? null : () => act('complete'),
                    child: const Text('Shaqada waa dhammaatay'),
                  ),
              ] else if ([
                'Received',
                'Assigned',
                'OnTheWay',
              ].contains(item!['status']))
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final yes = await showDialog<bool>(
                            context: c,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Jooji dalabka?'),
                              content: const Text(
                                'Ma hubtaa inaad joojinayso dalabkan?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Maya'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Haa, jooji'),
                                ),
                              ],
                            ),
                          );
                          if (yes == true) {
                            await act('cancel');
                          }
                        },
                  child: const Text('Jooji dalabka'),
                ),
            ],
          ),
  );
}
