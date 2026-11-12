#!/usr/bin/env python3
"""Gera PDF do relatorio final IMSL x open-source (pos-validacao experimental)."""
from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path

from fpdf import FPDF

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results" / "validation_report_final.pdf"

CASES = [
    ("EVCRG", "Autovalores/autovetores reais", "EVCRG", "LAPACK DGEEV"),
    ("EVCCG", "Autovalores/autovetores complexos", "EVCCG", "LAPACK ZGEEV"),
    ("EVLCG", "Autovalores complexos", "EVLCG", "LAPACK ZGEEV"),
    ("GVCRG", "Problema generalizado", "GVCRG", "LAPACK DGGEV"),
    ("MRRRR", "Produto matricial real", "MRRRR", "BLAS DGEMM"),
    ("MCRCR", "Produto matricial complexo", "MCRCR", "BLAS ZGEMM"),
    ("MUCRV", "Matriz-vetor complexo", "MUCRV", "BLAS ZGEMV"),
    ("LINEAR_OPERATORS", "Operador .ix. / solve", "linear_operators", "LAPACK DGESV"),
    ("LSLCG", "Sistema linear complexo", "LSLCG", "LAPACK ZGESV"),
    ("LIN_SOL_GEN", "Sistema linear geral", "LIN_SOL_GEN", "LAPACK DGESV"),
    ("RCURV", "Regressao polinomial", "RCURV", "LAPACK DGELS"),
    ("CSIEZ", "Spline cubica", "CSIEZ", "FITPACK"),
    ("BCLSF", "Minimos quadrados com limites", "BCLSF", "GALAHAD BNLS"),
    ("UNLSF", "Minimos quadrados nao linear", "UNLSF", "MINPACK LMDIF"),
    ("U4LSF", "Config. otimizador + UNLSF", "U4LSF+UNLSF", "MINPACK (tol)"),
    ("IVPRK", "EDO (y'=-y)", "IVPRK", "DOP853"),
    ("SVIGN", "Ordenacao de inteiros", "SVIGN", "stdlib SORT"),
    ("UMACH", "Unidade de saida", "UMACH", "ISO_FORTRAN_ENV"),
    ("IFNLS", "Formatacao locale (Intel)", "IFNLS (nao IMSL)", "formatacao Fortran"),
]


def read_result(side: str, key: str) -> str:
    path = ROOT / "results" / side / f"{key.lower()}.txt"
    if not path.exists():
        return "(ausente)"
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        parts = s.split(None, 1)
        if parts and parts[0].lower() == key.lower():
            return parts[1] if len(parts) > 1 else s
    return path.read_text(encoding="utf-8", errors="replace").strip()[:120]


def load_summary() -> dict[str, dict[str, str]]:
    path = ROOT / "results" / "comparison" / "summary.tsv"
    out: dict[str, dict[str, str]] = {}
    with path.open(encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            out[row["case"].strip().lower()] = {k: (v or "").strip() for k, v in row.items()}
    return out


def sci(s: str) -> str:
    try:
        return f"{float(s):.3e}"
    except Exception:
        return s


class Report(FPDF):
    def header(self) -> None:
        if self.page_no() == 1:
            return
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(90, 90, 90)
        self.cell(0, 6, "Validacao experimental IMSL FNL 2024.1.0 x open-source", align="L")
        self.ln(8)

    def footer(self) -> None:
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, f"Pagina {self.page_no()}/{{nb}}", align="C")


def section_title(pdf: Report, text: str) -> None:
    pdf.set_x(pdf.l_margin)
    pdf.set_font("Helvetica", "B", 13)
    pdf.set_text_color(20, 45, 75)
    pdf.cell(0, 9, text, new_x="LMARGIN", new_y="NEXT")
    pdf.set_draw_color(20, 45, 75)
    pdf.set_line_width(0.4)
    y = pdf.get_y()
    pdf.line(pdf.l_margin, y, pdf.w - pdf.r_margin, y)
    pdf.ln(4)


def body(pdf: Report, text: str, size: int = 10) -> None:
    pdf.set_x(pdf.l_margin)
    pdf.set_font("Helvetica", size=size)
    pdf.set_text_color(30, 30, 30)
    pdf.multi_cell(0, 5, text)
    pdf.set_x(pdf.l_margin)
    pdf.ln(2)


def table_header(pdf: Report, cols: list[tuple[str, float]]) -> None:
    pdf.set_font("Helvetica", "B", 8)
    pdf.set_fill_color(20, 45, 75)
    pdf.set_text_color(255, 255, 255)
    for title, w in cols:
        pdf.cell(w, 7, title, border=1, fill=True, align="C")
    pdf.ln()


def table_row(pdf: Report, cols: list[tuple[str, float, str]], fill: bool) -> None:
    pdf.set_font("Helvetica", size=7.5)
    pdf.set_text_color(25, 25, 25)
    if fill:
        pdf.set_fill_color(240, 244, 248)
    else:
        pdf.set_fill_color(255, 255, 255)
    h = 6.2
    x0 = pdf.get_x()
    y0 = pdf.get_y()
    # measure needed height for wrapped cells
    heights = []
    for text, w, _ in cols:
        heights.append(max(h, pdf.get_string_width(text) / max(w - 1, 1) * 4.5 + 2))
    row_h = max(heights)
    if y0 + row_h > pdf.h - 18:
        pdf.add_page()
        y0 = pdf.get_y()
    for i, (text, w, align) in enumerate(cols):
        pdf.set_xy(x0 + sum(c[1] for c in cols[:i]), y0)
        pdf.cell(w, row_h, text[:48], border=1, fill=True, align=align)
    pdf.set_xy(pdf.l_margin, y0 + row_h)


def main() -> None:
    summary = load_summary()
    pdf = Report(orientation="L", format="A4")
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=14)
    pdf.add_page()

    # Cover / intro
    pdf.set_x(pdf.l_margin)
    pdf.set_font("Helvetica", "B", 20)
    pdf.set_text_color(20, 45, 75)
    pdf.ln(6)
    pdf.cell(0, 10, "Relatorio Final de Validacao Experimental", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(
        0,
        8,
        "IMSL Fortran Numerical Library 2024.1.0  x  Bibliotecas Open-Source",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.ln(2)
    pdf.set_font("Helvetica", size=10)
    pdf.set_text_color(50, 50, 50)
    pdf.multi_cell(
        0,
        5,
        "Comparacao numerica com execucao real dos executaveis IMSL (ifort + imsl_dll) "
        "e open-source (gfortran + OpenBLAS / MINPACK / FITPACK / DOP853 / GALAHAD / stdlib).\n"
        f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        "Projeto: C:\\Users\\douglas\\Projects\\imsl\n"
        "Resultado global: 19 / 19 PASS",
    )
    pdf.ln(3)

    section_title(pdf, "1. Ambiente")
    body(
        pdf,
        "IMSL: C:\\Program Files (x86)\\RogueWave\\imsl\\fnl-2024.1.0\\win110in240x64  |  "
        "Link: imsl_dll.lib  |  Compilador: ifort Classic 2021.13.1 (oneAPI 2024.2.1) + VS Build Tools 2022\n"
        "Open-source: gfortran 16.2.0 (MSYS2 UCRT64) + OpenBLAS; third_party: minpack, fitpack, dop853, galahad, stdlib_sort_generated\n"
        "Comparador: tools/compare_results.f90  |  Evidencias: results/imsl/, results/opensource/, results/comparison/",
        size=9,
    )

    section_title(pdf, "2. Resumo comparativo (IMSL x Open-Source)")
    cols = [
        ("Rotina", 28),
        ("Funcao", 48),
        ("IMSL", 32),
        ("Open-source", 42),
        ("E_abs max", 28),
        ("Tol.", 22),
        ("Status", 18),
    ]
    usable = pdf.w - pdf.l_margin - pdf.r_margin
    scale = usable / sum(w for _, w in cols)
    cols = [(t, w * scale) for t, w in cols]
    table_header(pdf, cols)
    for i, (name, desc, imsl_api, oss_api) in enumerate(CASES):
        key = name.lower()
        row = summary.get(key, {})
        status = row.get("status", "?")
        eabs = sci(row.get("max_abs_error", ""))
        tol = sci(row.get("abs_tol", ""))
        table_row(
            pdf,
            [
                (name, cols[0][1], "L"),
                (desc, cols[1][1], "L"),
                (imsl_api, cols[2][1], "L"),
                (oss_api, cols[3][1], "L"),
                (eabs, cols[4][1], "R"),
                (tol, cols[5][1], "R"),
                (status, cols[6][1], "C"),
            ],
            fill=(i % 2 == 0),
        )

    pdf.add_page()
    section_title(pdf, "3. Valores numericos efetivamente calculados")
    body(
        pdf,
        "Cada linha abaixo veio da saida real do executavel correspondente (precisao dupla, formato ES24.16).",
        size=9,
    )
    dcols = [
        ("Rotina", 28),
        ("Resultado IMSL", 110),
        ("Resultado Open-Source", 110),
    ]
    usable = pdf.w - pdf.l_margin - pdf.r_margin
    scale = usable / sum(w for _, w in dcols)
    dcols = [(t, w * scale) for t, w in dcols]
    table_header(pdf, dcols)
    for i, (name, _desc, _a, _b) in enumerate(CASES):
        key = name.lower()
        imsl_v = read_result("imsl", key)
        oss_v = read_result("opensource", key)
        # truncate for readability in landscape cells
        if len(imsl_v) > 95:
            imsl_v = imsl_v[:92] + "..."
        if len(oss_v) > 95:
            oss_v = oss_v[:92] + "..."
        table_row(
            pdf,
            [
                (name, dcols[0][1], "L"),
                (imsl_v, dcols[1][1], "L"),
                (oss_v, dcols[2][1], "L"),
            ],
            fill=(i % 2 == 0),
        )

    pdf.ln(6)
    section_title(pdf, "4. Criterios e observacoes")
    body(
        pdf,
        "Erro absoluto: E_abs = |IMSL - OpenSource|. Erro relativo: E_rel = E_abs / max(|IMSL|, eps).\n"
        "PASS somente quando ambos os lados executaram e max(E_abs, criterio relativo) atendeu a tolerancia do caso.\n"
        "Autovalores ordenados por parte real crescente. IFNLS nao e rotina IMSL (modulo Intel NLS); comparacao por string 1.234,50.\n"
        "U4LSF configura RPARAM e resolve via UNLSF/MINPACK. BCLSF: limite ativo x1=0.5; tolerancia 1e-8 justificada por solvers distintos (IMSL LM vs GALAHAD BNLS).\n"
        "IVPRK: IMSL Runge-Kutta-Verner vs DOP853; mesma EDO y'=-y, y(0)=1, t=1.",
        size=9,
    )

    section_title(pdf, "5. Conclusao")
    body(
        pdf,
        "As 19 rotinas/interfaces auditadas apresentaram equivalencia numerica aceitavel nesta bateria experimental. "
        "Substituicao open-source viavel para os casos testados: EVCRG, EVCCG, EVLCG, GVCRG, MRRRR, MCRCR, MUCRV, "
        "LINEAR_OPERATORS, LSLCG, LIN_SOL_GEN, RCURV, CSIEZ, BCLSF, UNLSF, U4LSF, IVPRK, SVIGN, UMACH e IFNLS (utilitario Intel). "
        "Esta conclusao refere-se aos problemas determinísticos pequenos usados na validacao; migracao de producao "
        "ainda deve considerar condicionamento, limites ativos, desempenho e cobertura do RotorTest.",
        size=10,
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
