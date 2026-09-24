/// Connexion, inscription et mot de passe oublié.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../config/theme.dart';
import '../../data/depot.dart';
import '../../providers.dart';
import '../widgets.dart';
import 'ouverture.dart';

/// La mise en page commune : logo et nom en haut, formulaire centré.
class _Accueil extends StatelessWidget {
  const _Accueil({required this.titre, required this.sousTitre, required this.children, this.retour = false});
  final String titre;
  final String sousTitre;
  final List<Widget> children;
  final bool retour;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Fond(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: gouttiere(context, min: 22, largeur: 440), vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (retour)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.go('/connexion'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Retour',
                      ),
                    ),
                  const Center(child: Logo(taille: 76)),
                  const SizedBox(height: 18),
                  const Center(child: NomBeVannes(taille: 28)),
                  const SizedBox(height: 34),
                  Text(titre, style: K.display(24)),
                  const SizedBox(height: 6),
                  Text(sousTitre, style: const TextStyle(color: K.muted, fontSize: 15, height: 1.4)),
                  const SizedBox(height: 22),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un encadré d'erreur sous le formulaire.
class _Erreur extends StatelessWidget {
  const _Erreur(this.message);
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: K.fast,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: K.dangerSoft, borderRadius: BorderRadius.circular(K.radius)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: K.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message!, style: const TextStyle(color: K.text)),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Champ mot de passe, avec l'œil pour l'afficher.
class _ChampMotDePasse extends StatefulWidget {
  const _ChampMotDePasse({required this.controleur, this.nouveau = false, this.onSubmitted});
  final TextEditingController controleur;
  final bool nouveau;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_ChampMotDePasse> createState() => _ChampMotDePasseState();
}

class _ChampMotDePasseState extends State<_ChampMotDePasse> {
  var _cache = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controleur,
      obscureText: _cache,
      autofillHints: [widget.nouveau ? AutofillHints.newPassword : AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: widget.onSubmitted,
      validator: (v) => (v ?? '').length < 6 ? '6 caractères au moins' : null,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _cache = !_cache),
          icon: Icon(_cache ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: _cache ? 'Afficher' : 'Masquer',
        ),
      ),
    );
  }
}

String? _verifierEmail(String? v) {
  final e = (v ?? '').trim();
  if (e.isEmpty) return 'Indique ton adresse e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) return 'Adresse e-mail invalide';
  return null;
}

class EcranConnexion extends ConsumerStatefulWidget {
  const EcranConnexion({super.key});

  @override
  ConsumerState<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends ConsumerState<EcranConnexion> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: modeDemo ? 'demo@bevannes.fr' : '');
  final _mdp = TextEditingController(text: modeDemo ? 'bevannes' : '');
  var _occupe = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    _mdp.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      await ref.read(depotProvider).connexion(email: _email.text, motDePasse: _mdp.text);
    } on ErreurDepot catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Accueil(
      titre: 'Connexion',
      sousTitre: 'Le lieu du jour t’attend quelque part dans Vannes.',
      children: [
        if (modeDemo) ...[
          const Carte(
            padding: EdgeInsets.all(14),
            couleur: K.accentSoft,
            bordure: Colors.transparent,
            child: Row(
              children: [
                Icon(Icons.science_outlined, color: K.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mode démo : tout reste sur ce téléphone. N’importe quelle adresse fait l’affaire.',
                    style: TextStyle(color: K.textSoft, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: _verifierEmail,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                _ChampMotDePasse(controleur: _mdp, onSubmitted: (_) => _envoyer()),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => context.go('/oubli'), child: const Text('Mot de passe oublié ?')),
        ),
        const SizedBox(height: 6),
        _Erreur(_erreur),
        BoutonPrincipal(texte: 'Se connecter', onPressed: _envoyer, occupe: _occupe),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Pas encore de compte ?', style: TextStyle(color: K.muted)),
            TextButton(onPressed: () => context.go('/inscription'), child: const Text('Créer un compte')),
          ],
        ),
      ],
    );
  }
}

class EcranInscription extends ConsumerStatefulWidget {
  const EcranInscription({super.key});

  @override
  ConsumerState<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends ConsumerState<EcranInscription> {
  final _form = GlobalKey<FormState>();
  final _pseudo = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  var _occupe = false;
  String? _erreur;

  @override
  void dispose() {
    _pseudo.dispose();
    _email.dispose();
    _mdp.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      await ref.read(depotProvider).inscription(pseudo: _pseudo.text, email: _email.text, motDePasse: _mdp.text);
    } on ErreurDepot catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Accueil(
      titre: 'Créer un compte',
      sousTitre: 'Ton pseudo apparaîtra au classement, rien d’autre n’est public.',
      retour: true,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _pseudo,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.nickname],
                  maxLength: 20,
                  validator: (v) => erreurPseudo(v ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Pseudo',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: _verifierEmail,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                _ChampMotDePasse(controleur: _mdp, nouveau: true, onSubmitted: (_) => _envoyer()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Erreur(_erreur),
        BoutonPrincipal(texte: 'Créer mon compte', onPressed: _envoyer, occupe: _occupe),
      ],
    );
  }
}

class EcranOubli extends ConsumerStatefulWidget {
  const EcranOubli({super.key});

  @override
  ConsumerState<EcranOubli> createState() => _EcranOubliState();
}

class _EcranOubliState extends ConsumerState<EcranOubli> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _occupe = false;
  var _envoye = false;
  String? _erreur;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _occupe = true;
      _erreur = null;
    });
    try {
      await ref.read(depotProvider).motDePasseOublie(_email.text);
      if (mounted) setState(() => _envoye = true);
    } on ErreurDepot catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _occupe = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Accueil(
      titre: 'Mot de passe oublié',
      sousTitre: 'On t’envoie un lien pour en choisir un nouveau.',
      retour: true,
      children: [
        if (_envoye)
          Carte(
            child: Column(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: K.accent, size: 34),
                const SizedBox(height: 10),
                Text(
                  'Si un compte existe pour ${_email.text.trim()}, le lien est en route. Pense aux indésirables.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: K.textSoft, height: 1.45),
                ),
                const SizedBox(height: 16),
                BoutonSecondaire(texte: 'Retour à la connexion', onPressed: () => context.go('/connexion')),
              ],
            ),
          )
        else ...[
          Form(
            key: _form,
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: _verifierEmail,
              onFieldSubmitted: (_) => _envoyer(),
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.alternate_email_rounded)),
            ),
          ),
          const SizedBox(height: 20),
          _Erreur(_erreur),
          BoutonPrincipal(texte: 'Envoyer le lien', onPressed: _envoyer, occupe: _occupe),
        ],
      ],
    );
  }
}
