from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE = ROOT / "source" / "vanilla" / "Teams" / "0" / "Croatia.tres"
OUTPUT = ROOT / "mods" / "world-cup-2026" / "files" / "Teams" / "0"
COLOR_FIELDS = (
    "Shirt1Color", "Shirt2Color", "Shirt3Color", "ShortColor", "KeeperColor",
    "altShirt1Color", "altShirt2Color", "altShirt3Color", "altShortColor", "numberColor",
)


def colors(main, secondary, accent, shorts, keeper, alternate, alternate_secondary, number):
    return (main, secondary, accent, shorts, keeper, alternate, alternate_secondary,
            alternate_secondary, alternate, number)


TEAMS = {
    "South Africa": ("RSA", colors("0.95, 0.78, 0.02", "0.02, 0.40, 0.18", "0.00, 0.00, 0.00", "0.02, 0.40, 0.18", "0.60, 0.60, 0.60", "0.02, 0.40, 0.18", "0.95, 0.78, 0.02", "0.95, 0.78, 0.02"), ["Ronwen Williams", "Bruce Bvuma", "Khuliso Mudau", "Teboho Mokoena", "Percy Tau", "Themba Zwane", "Lyle Foster", "Evidence Makgopa", "Relebohile Mofokeng", "Tashreeq Matthews", "Aubrey Modiba", "Sipho Mbule"]),
    "Czechia": ("CZE", colors("0.78, 0.04, 0.08", "0.98, 0.98, 0.98", "0.05, 0.15, 0.45", "0.05, 0.15, 0.45", "0.95, 0.75, 0.02", "0.98, 0.98, 0.98", "0.78, 0.04, 0.08", "0.78, 0.04, 0.08"), ["Jindrich Stanek", "Tomas Vaclik", "Vladimir Coufal", "David Zima", "Tomas Soucek", "Alex Kral", "Adam Hlozek", "Patrik Schick", "Pavel Sulc", "Ladislav Krejci", "Jan Kuchta", "Matej Kovar"]),
    "Haiti": ("HAI", colors("0.04, 0.18, 0.55", "0.92, 0.08, 0.12", "0.98, 0.98, 0.98", "0.04, 0.18, 0.55", "0.95, 0.75, 0.02", "0.92, 0.08, 0.12", "0.04, 0.18, 0.55", "0.04, 0.18, 0.55"), ["Johnny Placide", "Josue Duverger", "Carlens Arcus", "Ricardo Ade", "Duckens Nazon", "Frantzdy Pierrot", "Derrick Etienne", "Bryan Alceus", "Danley Jean Jacques", "Louicius Don Deedson", "Steeven Saba", "Carnejy Antoine"]),
    "Paraguay": ("PAR", colors("0.86, 0.05, 0.10", "0.98, 0.98, 0.98", "0.05, 0.16, 0.48", "0.98, 0.98, 0.98", "0.95, 0.75, 0.02", "0.98, 0.98, 0.98", "0.86, 0.05, 0.10", "0.86, 0.05, 0.10"), ["Carlos Coronel", "Roberto Fernandez", "Junior Alonso", "Fabian Balbuena", "Matias Villasanti", "Miguel Almiron", "Ramon Sosa", "Julio Enciso", "Adam Bareiro", "Diego Gomez", "Matias Rojas", "Kaku Romero"]),
    "Curaçao": ("CUW", colors("0.03, 0.25, 0.65", "0.98, 0.98, 0.98", "0.95, 0.35, 0.05", "0.03, 0.25, 0.65", "0.95, 0.75, 0.02", "0.98, 0.98, 0.98", "0.03, 0.25, 0.65", "0.03, 0.25, 0.65"), ["Eloy Room", "Trevor Doornbusch", "Cuco Martina", "Braydun Wintjens", "Leandro Bacuna", "Godsway Donkor", "Jeremy Antonisse", "Kenji Gorre", "Rangelo Janga", "Juninho Bacuna", "Michael Maria", "Darryl Lachman"]),
    "New Zealand": ("NZL", colors("0.02, 0.02, 0.02", "0.98, 0.98, 0.98", "0.25, 0.25, 0.25", "0.02, 0.02, 0.02", "0.95, 0.75, 0.02", "0.98, 0.98, 0.98", "0.02, 0.02, 0.02", "0.02, 0.02, 0.02"), ["Chris Wood", "Liberato Cacace", "Winston Reid", "Bill Tuiloma", "Joe Bell", "Marko Stamenic", "Sarpreet Singh", "Kosta Barbarouses", "Elijah Just", "Alex Rufer", "Matt Garbett", "Michael Boxall"]),
    "Cabo Verde": ("CPV", colors("0.03, 0.20, 0.58", "0.98, 0.98, 0.98", "0.86, 0.05, 0.10", "0.03, 0.20, 0.58", "0.95, 0.75, 0.02", "0.86, 0.05, 0.10", "0.03, 0.20, 0.58", "0.03, 0.20, 0.58"), ["Vozinha", "Stopira", "Jamiro Monteiro", "Kenny Rocha Santos", "Ryan Mendes", "Garry Rodrigues", "Bebe", "Julio Tavares", "Djaniny", "Logan Costa", "Roberto Lopes", "Steven Moreira"]),
    "Norway": ("NOR", colors("0.82, 0.04, 0.10", "0.05, 0.18, 0.48", "0.98, 0.98, 0.98", "0.98, 0.98, 0.98", "0.95, 0.75, 0.02", "0.05, 0.18, 0.48", "0.82, 0.04, 0.10", "0.82, 0.04, 0.10"), ["Orjan Nyland", "Kristoffer Ajer", "Martin Odegaard", "Erling Haaland", "Alexander Sorloth", "Julian Ryerson", "Morten Thorsby", "Sander Berge", "Oscar Bobb", "Antonio Nusa", "Andreas Schjelderup", "Fredrik Aursnes"]),
    "Iraq": ("IRQ", colors("0.02, 0.42, 0.20", "0.98, 0.98, 0.98", "0.86, 0.05, 0.10", "0.98, 0.98, 0.98", "0.95, 0.75, 0.02", "0.86, 0.05, 0.10", "0.02, 0.42, 0.20", "0.02, 0.42, 0.20"), ["Jalal Hassan", "Ahmed Ibrahim", "Ali Adnan", "Rebin Solaka", "Amjad Attwan", "Bashar Resan", "Osama Rashid", "Aymen Hussein", "Mohanad Ali", "Ali Jasim", "Ibrahim Bayesh", "Zidane Iqbal"]),
    "Austria": ("AUT", colors("0.85, 0.03, 0.08", "0.98, 0.98, 0.98", "0.85, 0.03, 0.08", "0.98, 0.98, 0.98", "0.95, 0.75, 0.02", "0.98, 0.98, 0.98", "0.85, 0.03, 0.08", "0.85, 0.03, 0.08"), ["Heinz Lindner", "Philipp Lienhart", "David Alaba", "Stefan Posch", "Marcel Sabitzer", "Konrad Laimer", "Christoph Baumgartner", "Marko Arnautovic", "Michael Gregoritsch", "Florian Grillitsch", "Romano Schmid", "Alexander Prass"]),
    "Jordan": ("JOR", colors("0.04, 0.04, 0.04", "0.92, 0.05, 0.08", "0.02, 0.42, 0.20", "0.98, 0.98, 0.98", "0.95, 0.75, 0.02", "0.92, 0.05, 0.08", "0.98, 0.98, 0.98", "0.92, 0.05, 0.08"), ["Yazeed Abulaila", "Abdallah Nasib", "Nour Al-Din Al-Rawabdeh", "Mousa Al-Taamari", "Yazan Al-Naimat", "Ali Olwan", "Mahmoud Al-Mardi", "Nizar Mahmoud", "Ihsan Haddad", "Salem Al-Ajalin", "Anas Bani Yaseen", "Ahmad Samih"]),
    "Congo DR": ("COD", colors("0.02, 0.35, 0.72", "0.98, 0.98, 0.98", "0.92, 0.72, 0.02", "0.02, 0.35, 0.72", "0.95, 0.75, 0.02", "0.98, 0.98, 0.98", "0.02, 0.35, 0.72", "0.02, 0.35, 0.72"), ["Lionel Mpasi", "Chancel Mbemba", "Arthur Masuaku", "Merveille Bokadi", "Samuel Moutoussamy", "Edo Kayembe", "Gael Kakuta", "Yoane Wissa", "Cedric Bakambu", "Simon Banza", "Silas Katompa", "Fiston Mayele"]),
    "Uzbekistan": ("UZB", colors("0.98, 0.98, 0.98", "0.05, 0.35, 0.72", "0.02, 0.48, 0.28", "0.98, 0.98, 0.98", "0.95, 0.75, 0.02", "0.05, 0.35, 0.72", "0.98, 0.98, 0.98", "0.98, 0.98, 0.98"), ["Utkir Yusupov", "Abdukodir Khusanov", "Eldor Shomurodov", "Oston Urunov", "Jaloliddin Masharipov", "Odiljon Hamrobekov", "Abbosbek Fayzullaev", "Igor Sergeev", "Rustam Ashurmatov", "Khozhimat Erkinov", "Sherzod Nasrullaev", "Jamshid Iskanderov"]),
}

KITS = {
    "South Africa": (5, 2),  # diagonal home / striped away
    "Czechia": (1, 2),  # clean red home / striped away
    "Haiti": (4, 10),  # central stripe / split away
    "Paraguay": (5, 2),  # diagonal sash / striped away
    "Curaçao": (6, 1),  # panel sleeves / clean away
    "New Zealand": (1, 4),  # all black home / central-stripe away
    "Cabo Verde": (2, 6),  # vertical stripes / blue-panel away
    "Norway": (8, 11),  # horizontal band / double-band away
    "Iraq": (1, 2),  # clean green home / striped away
    "Austria": (8, 1),  # horizontal band / clean away
    "Jordan": (10, 5),  # split home / diagonal away
    "Congo DR": (5, 4),  # diagonal sash / central stripe away
    "Uzbekistan": (2, 6),  # striped home / panel-sleeve away
}


def main() -> None:
    template = TEMPLATE.read_text(encoding="utf-8")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, (shortname, team_colors, players) in TEAMS.items():
        resource = template.replace('teamname = "Croatia"', f'teamname = "{name}"', 1)
        resource = resource.replace('shortname = "Cro"', f'shortname = "{shortname}"', 1)
        for field, color in zip(COLOR_FIELDS, team_colors):
            resource = re.sub(rf'^{field} = .*$', f'{field} = Color( {color}, 1 )', resource, flags=re.MULTILINE)
        home_kit, away_kit = KITS[name]
        resource = re.sub(r'^shirtType = .*$', f'shirtType = {home_kit}', resource, flags=re.MULTILINE)
        resource = re.sub(r'^shirt2Type = .*$', f'shirt2Type = {away_kit}', resource, flags=re.MULTILINE)
        names = iter(players)
        resource = re.sub(r'("name": ")[^"]+(")', lambda match: match.group(1) + next(names) + match.group(2), resource)
        (OUTPUT / f"{name}.tres").write_text(resource, encoding="utf-8")


if __name__ == "__main__":
    main()
