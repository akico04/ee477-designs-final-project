#!/usr/bin/env python3


def conway_next_state(current_cell: int, neighbors_bits: str) -> int:
    """Return next Conway Game of Life state."""
    live_neighbors = neighbors_bits.count("1")

    if current_cell == 1:
        # Live cell survives with 2 or 3 live neighbors
        return 1 if live_neighbors in (2, 3) else 0
    else:
        # Dead cell becomes alive with exactly 3 live neighbors
        return 1 if live_neighbors == 3 else 0


def emit_test_case(update_value: int, neighbors_bits: str) -> None:
    expected = conway_next_state(update_value, neighbors_bits)
    live_count = neighbors_bits.count("1")

    print(f"# Update value = {update_value}")
    print(f"0001__0_{update_value}_00000000")

    print(f"# Enable, neighbors = 8'b{neighbors_bits}, live neighbors = {live_count}")
    print(f"0001__1_0_{neighbors_bits}")

    print(f"# Expected next state = {expected}")
    print(f"0010__000000000_{expected}")
    print()


def main() -> None:
    for update_value in (0, 1):
        print(f"# ===============================")
        print(f"# Tests with update value = {update_value}")
        print(f"# ===============================")
        print()

        for n in range(256):
            neighbors_bits = format(n, "08b")
            emit_test_case(update_value, neighbors_bits)


if __name__ == "__main__":
    main()
