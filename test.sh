#!/bin/bash

PHILO_DIR="../philo"
PHILO_BIN="$PHILO_DIR/philo"
MAKE="make -C $PHILO_DIR"

PASS=0
FAIL=0
LEAK_PASS=0
LEAK_FAIL=0
RACE_PASS=0
RACE_FAIL=0
HELGRIND_PASS=0
HELGRIND_FAIL=0
DRD_PASS=0
DRD_FAIL=0

FAILED_TESTS=()
FAILED_LEAK_TESTS=()
FAILED_HELGRIND_TESTS=()
FAILED_DRD_TESTS=()

function print_header() {
    echo -e "\033[1;32m==== mmakhlou Philosopher Tester ===="
    echo -e "Project by mmakhlou <mmakhlou@student.42.fr>\033[0m"
}

function build_project() {
    echo -e "\033[1;34m[BUILD]\033[0m Compiling philo..."
    $MAKE fclean && $MAKE
    if [ ! -f "$PHILO_BIN" ]; then
        echo -e "\033[1;31m[ERROR]\033[0m Build failed!"
        exit 1
    fi
}

function run_test() {
    DESC="$1"
    shift
    ARGS=("$@")
    local test_failed=false
    local expect_error=false
    local expect_death=false
    local expect_must_eat=false
    local must_eat_count=0

    if [[ "$DESC" == *"Invalid arguments"* ]]; then
        expect_error=true
    elif [[ "$DESC" == *"should die"* ]]; then
        expect_death=true
    elif [[ "$DESC" == *"must eat"* ]]; then
        expect_must_eat=true
        # Get the must_eat count from the last argument
        must_eat_count=${ARGS[-1]}
    fi

    for i in {1..3}; do
        echo -e "\033[1;33m[TEST]\033[0m $DESC (run $i)"

        if [ "$expect_error" = true ]; then
            $PHILO_BIN "${ARGS[@]}"
            STATUS=$?
            if [ $STATUS -eq 2 ]; then
                echo -e "\033[1;32m[OK]\033[0m Correctly returned error (2)"
                ((PASS++))
            else
                echo -e "\033[1;31m[KO]\033[0m Expected error return (2), got $STATUS"
                ((FAIL++))
                test_failed=true
            fi
        elif [ "$expect_death" = true ]; then
            $PHILO_BIN "${ARGS[@]}" > output.txt 2>&1 &
            PID=$!
            sleep 2
            if ! kill -0 $PID 2>/dev/null; then
                if grep -q "died" output.txt; then
                    echo -e "\033[1;32m[OK]\033[0m Philosopher died as expected"
                    ((PASS++))
                else
                    echo -e "\033[1;31m[KO]\033[0m Program exited but no death message"
                    ((FAIL++))
                    test_failed=true
                fi
            else
                echo -e "\033[1;31m[KO]\033[0m Program didn't exit after death"
                kill $PID 2>/dev/null
                ((FAIL++))
                test_failed=true
            fi
            rm -f output.txt
        elif [ "$expect_must_eat" = true ]; then
            $PHILO_BIN "${ARGS[@]}" > output.txt 2>&1 &
            PID=$!
            sleep 15
            if ! kill -0 $PID 2>/dev/null; then
                if ! grep -q "died" output.txt; then
                    # Count meals for each philosopher
                    local nb_philos=${ARGS[0]}
                    local all_ate_enough=true
                    for ((philo=1; philo<=nb_philos; philo++)); do
                        local meals=$(grep -c "is eating" output.txt | grep -o "[0-9]*")
                        if [ "$meals" -lt "$must_eat_count" ]; then
                            echo -e "\033[1;31m[KO]\033[0m Philosopher $philo only ate $meals times (needed $must_eat_count)"
                            all_ate_enough=false
                            break
                        fi
                    done
                    if [ "$all_ate_enough" = true ]; then
                        echo -e "\033[1;32m[OK]\033[0m All philosophers ate $must_eat_count times"
                        ((PASS++))
                    else
                        ((FAIL++))
                        test_failed=true
                    fi
                else
                    echo -e "\033[1;31m[KO]\033[0m Program exited with death message"
                    ((FAIL++))
                    test_failed=true
                fi
            else
                echo -e "\033[1;31m[KO]\033[0m Program didn't exit after all philosophers ate enough times"
                kill $PID 2>/dev/null
                ((FAIL++))
                test_failed=true
            fi
            rm -f output.txt
        else
            $PHILO_BIN "${ARGS[@]}" > /dev/null 2>&1 &
            PID=$!
            sleep 10
            if kill -0 $PID 2>/dev/null; then
                echo -e "\033[1;32m[OK]\033[0m Program still running after 10s"
                kill $PID 2>/dev/null
                ((PASS++))
            else
                echo -e "\033[1;31m[KO]\033[0m Program exited early"
                ((FAIL++))
                test_failed=true
            fi
        fi
    done

    if [ "$test_failed" = true ]; then
        FAILED_TESTS+=("$DESC (Args: ${ARGS[*]})")
    fi
}

function run_leak_test() {
    DESC="$1"
    shift
    ARGS=("$@")
    local test_failed=false
    echo -e "\033[1;36m[LEAK TEST]\033[0m $DESC"
    timeout 10s valgrind --leak-check=full --error-exitcode=42 $PHILO_BIN "${ARGS[@]}" > /dev/null 2>&1
    STATUS=$?
    if [ $STATUS -eq 42 ]; then
        echo -e "\033[1;31m[KO]\033[0m Memory leak detected!"
        ((LEAK_FAIL++))
        test_failed=true
    elif [ $STATUS -eq 124 ]; then
        echo -e "\033[1;32m[OK]\033[0m No leaks detected (timeout after 10s)."
        ((LEAK_PASS++))
    else
        echo -e "\033[1;32m[OK]\033[0m No leaks."
        ((LEAK_PASS++))
    fi
    if [ "$test_failed" = true ]; then
        FAILED_LEAK_TESTS+=("$DESC (Args: ${ARGS[*]})")
    fi
}

function run_helgrind_test() {
    DESC="$1"
    shift
    ARGS=("$@")
    local test_failed=false
    echo -e "\033[1;36m[HELGRIND TEST]\033[0m $DESC"
    timeout 10s valgrind --tool=helgrind --error-exitcode=42 $PHILO_BIN "${ARGS[@]}" > /dev/null 2>&1
    STATUS=$?
    if [ $STATUS -eq 42 ]; then
        echo -e "\033[1;31m[KO]\033[0m Helgrind detected a potential **deadlock**!"
        ((HELGRIND_FAIL++))
        test_failed=true
    elif [ $STATUS -eq 124 ]; then
        echo -e "\033[1;32m[OK]\033[0m No deadlocks (timeout after 10s)."
        ((HELGRIND_PASS++))
    else
        echo -e "\033[1;32m[OK]\033[0m No deadlocks."
        ((HELGRIND_PASS++))
    fi
    if [ "$test_failed" = true ]; then
        FAILED_HELGRIND_TESTS+=("$DESC (Args: ${ARGS[*]})")
    fi
}

function run_drd_test() {
    DESC="$1"
    shift
    ARGS=("$@")
    local test_failed=false
    echo -e "\033[1;36m[DRD TEST]\033[0m $DESC"
    timeout 10s valgrind --tool=drd --error-exitcode=43 $PHILO_BIN "${ARGS[@]}" > /dev/null 2>&1
    STATUS=$?
    if [ $STATUS -eq 43 ]; then
        echo -e "\033[1;31m[KO]\033[0m DRD detected a **data race**!"
        ((DRD_FAIL++))
        test_failed=true
    elif [ $STATUS -eq 124 ]; then
        echo -e "\033[1;32m[OK]\033[0m No data races (timeout after 10s)."
        ((DRD_PASS++))
    else
        echo -e "\033[1;32m[OK]\033[0m No data races."
        ((DRD_PASS++))
    fi
    if [ "$test_failed" = true ]; then
        FAILED_DRD_TESTS+=("$DESC (Args: ${ARGS[*]})")
    fi
}

print_header
build_project

TESTS=(
    "Basic 5 philosophers|5 800 200 200"
    "1 philosopher (should die)|1 800 200 200"
    "All arguments, must eat 3|7 800 200 200 3"
    "Invalid arguments (should error)|0 800 200 200"
    "Invalid arguments (should error)|5 -1 200 200"
    "Stress test 10 philosophers|10 800 200 200"
)

LEAK_TESTS=(
    "Leak test: 5 philosophers|5 800 200 200"
    "Leak test: 1 philosopher|1 800 200 200"
    "Leak test: 10 philosopher|10 800 200 200"
)

HELGRIND_TESTS=(
    "Helgrind test: 5 philosophers|5 800 200 200"
    "Helgrind test: 1 philosopher|1 800 200 200"
    "Helgrind test: 10 philosopher|10 800 200 200"
)

DRD_TESTS=(
    "DRD test: 5 philosophers|5 800 200 200"
    "DRD test: 1 philosopher|1 800 200 200"
    "DRD test: 10 philosopher|10 800 200 200"
)

for test in "${TESTS[@]}"; do
    DESC="${test%%|*}"
    ARGS="${test#*|}"
    run_test "$DESC" $ARGS
    echo
done

for test in "${LEAK_TESTS[@]}"; do
    DESC="${test%%|*}"
    ARGS="${test#*|}"
    run_leak_test "$DESC" $ARGS
    echo
done

for test in "${HELGRIND_TESTS[@]}"; do
    DESC="${test%%|*}"
    ARGS="${test#*|}"
    run_helgrind_test "$DESC" $ARGS
    echo
done

for test in "${DRD_TESTS[@]}"; do
    DESC="${test%%|*}"
    ARGS="${test#*|}"
    run_drd_test "$DESC" $ARGS
    echo
done

# Summary
TOTAL=$((PASS+FAIL))
LEAK_TOTAL=$((LEAK_PASS+LEAK_FAIL))
HELGRIND_TOTAL=$((HELGRIND_PASS+HELGRIND_FAIL))
DRD_TOTAL=$((DRD_PASS+DRD_FAIL))

echo -e "\033[1;35m==== SUMMARY ===="
echo -e "Functional tests: $PASS/$TOTAL passed, $FAIL failed."
echo -e "Leak tests: $LEAK_PASS/$LEAK_TOTAL passed, $LEAK_FAIL failed."
echo -e "Helgrind tests (deadlocks): $HELGRIND_PASS/$HELGRIND_TOTAL passed, $HELGRIND_FAIL failed."
echo -e "DRD tests (data races): $DRD_PASS/$DRD_TOTAL passed, $DRD_FAIL failed.\033[0m"

# Print failures
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "\n\033[1;31m==== FAILED FUNCTIONAL TESTS ====\033[0m"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "\033[1;31m- $test\033[0m"
    done
fi

if [ ${#FAILED_LEAK_TESTS[@]} -gt 0 ]; then
    echo -e "\n\033[1;31m==== FAILED LEAK TESTS ====\033[0m"
    for test in "${FAILED_LEAK_TESTS[@]}"; do
        echo -e "\033[1;31m- $test\033[0m"
    done
fi

if [ ${#FAILED_HELGRIND_TESTS[@]} -gt 0 ]; then
    echo -e "\n\033[1;31m==== FAILED HELGRIND TESTS (DEADLOCKS) ====\033[0m"
    for test in "${FAILED_HELGRIND_TESTS[@]}"; do
        echo -e "\033[1;31m- $test\033[0m"
    done
fi

if [ ${#FAILED_DRD_TESTS[@]} -gt 0 ]; then
    echo -e "\n\033[1;31m==== FAILED DRD TESTS (DATA RACES) ====\033[0m"
    for test in "${FAILED_DRD_TESTS[@]}"; do
        echo -e "\033[1;31m- $test\033[0m"
    done
fi
 