# 🧠 42 Philosophers Tester – by mmakhlou

**Repository:** `42_Philosophers_tester`

**Author:** Mario Makhlouta (`mmakhlou@student.42.fr`)

**Project:** Tester for the 42 School **Philosophers** project

---

## 📌 Overview

This is an advanced and automated tester for the 42 **philosophers** project. It validates your program across multiple dimensions:

* Functional correctness
* Memory leaks
* Thread race conditions
* Deadlocks and synchronization issues

The tester is **fully Bash-based**, using **Valgrind**, **Helgrind**, and **DRD** to ensure robustness.

---

## 📁 Project Structure

```
your_project_folder/
├── philo/                    # Your own 42 philosophers project
│   └── philo                # Compiled binary
├── 42_Philosophers_tester/    # This tester repo
│   ├── test.sh              # Main testing script
│   └── README.md
```

> ✅ Make sure the `philo` binary is compiled before running the tester.

---

## ⚙️ Setup

**Clone this tester** in the **same directory** as your `philo` folder:

```bash
git clone https://github.com/MarioMakhlouta/42_Philosophers_tester.git
cd 42_Philosophers_tester
chmod +x test.sh
```

---

## ▶️ Running the Tester

From inside `42_Philosophers_tester`:

```bash
./test.sh
```

The script will:

* Compile your `philo` project
* Run functional tests (normal, must\_eat, and invalid arguments)
* Run memory leak tests using `valgrind`
* Run deadlock detection via `helgrind`
* Run data race checks via `drd`

---

## 🧪 Tests Performed

### ✅ Functional Tests

* Normal operation with 5 or 10 philosophers
* Philosophers dying (edge case: 1 philosopher)
* `must_eat` value respected
* Invalid argument handling (error code = 2)
* Stress tests

### 🧼 Memory Leak Tests

Uses `valgrind` to ensure no heap memory leaks.

### 🔁 Concurrency Tests

* `helgrind`: Detects **mutex deadlocks**
* `drd`: Detects **data races**

Each test runs 3 times for consistency.

---

## 📊 Sample Output

```text
[TEST] Basic 5 philosophers (run 1)
[OK] Program still running after 10s

[LEAK TEST] Leak test: 5 philosophers
[OK] No leaks.

[HELGRIND TEST] Helgrind test: 10 philosophers
[KO] Helgrind detected a potential deadlock!

==== SUMMARY ====
Functional tests: 6/7 passed, 1 failed.
Leak tests: 3/3 passed, 0 failed.
Helgrind tests (deadlocks): 2/3 passed, 1 failed.
DRD tests (data races): 3/3 passed, 0 failed.
```

---

## 🛠 Dependencies

* Bash
* `make` & `gcc`
* [Valgrind](http://valgrind.org/) (for `valgrind`, `helgrind`, and `drd` tools)

Install on Debian/Ubuntu:

```bash
sudo apt update
sudo apt install valgrind
```

---

## 🧠 Tips

* Ensure `philo` binary is named correctly and in the `philo/` directory.
* Run the script in a **Linux environment** (e.g., WSL, Ubuntu, VM).
* Make sure `valgrind`, `helgrind`, and `drd` tools are available.
* You can add more test cases directly inside `test.sh` arrays: `TESTS`, `LEAK_TESTS`, etc.
