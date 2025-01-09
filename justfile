compile:
    typst compile examples/main.typ --root . example.pdf
thumbnail:
    typst compile -f png examples/main.typ --root . thumbnail.png
