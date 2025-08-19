import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/form_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 700;

    Widget card = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConsts.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child:
                      const Icon(Icons.favorite, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('Cuídalas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 18),
            Text('Bienvenida',
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text('Inicia sesión para continuar',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  FormInput(
                    controller: _email,
                    label: 'Correo',
                    hint: 'tu@correo.com',
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  FormInput(
                    controller: _password,
                    label: 'Contraseña',
                    hint: '••••••••',
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pushReplacementNamed(
                            context, AppConsts.routeUbicacion);
                      },
                      child: const Text('Ingresar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 420 : 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: card,
          ),
        ),
      ),
    );
  }
}
