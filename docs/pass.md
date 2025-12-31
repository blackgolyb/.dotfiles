# Pass (Password Manager)

## GPG + pass — експорт / імпорт ключів

### Знайти ID ключа

```bash
gpg --list-secret-keys --keyid-format=long
```

---

### Експорт ключів

```bash
gpg --export -a KEY_ID > public.gpg
gpg --export-secret-keys -a KEY_ID > private.gpg
gpg --export-ownertrust > ownertrust.txt
```

---

### Імпорт ключів

```bash
gpg --import public.gpg
gpg --import private.gpg
gpg --import-ownertrust ownertrust.txt
```

---

### Ініціалізація pass

```bash
pass init KEY_ID
```

(або кілька ключів)

```bash
pass init KEY_ID1 KEY_ID2
```

---

### Перевірка

```bash
pass insert test/example
pass show test/example
```

---
