// Factual surname list: https://obamawhitehouse.archives.gov/1600/presidents
// https://www.whitehousehistory.org/the-presidents-timeline
final presidentSurnames =
    ('washington,adams,jefferson,madison,monroe,jackson,van buren,harrison,'
            'tyler,polk,taylor,fillmore,pierce,buchanan,lincoln,johnson,grant,hayes,'
            'garfield,arthur,cleveland,mckinley,roosevelt,taft,wilson,harding,coolidge,'
            'hoover,truman,eisenhower,kennedy,nixon,ford,carter,reagan,bush,clinton,'
            'obama,trump,biden')
        .split(',');

final elementNames = <String>[
  'oganesson',
  'tennessine',
  'livermorium',
  'moscovium',
  'flerovium',
  'nihonium',
  'copernicium',
  'roentgenium',
  'darmstadtium',
  'meitnerium',
  'hassium',
  'bohrium',
  'seaborgium',
  'dubnium',
  'rutherfordium',
  'lawrencium',
  'nobelium',
  'mendelevium',
  'fermium',
  'einsteinium',
  'californium',
  'berkelium',
  ...'francium radium actinium thorium protactinium uranium neptunium plutonium americium curium'
      .split(' '),
  ...'caesium cesium barium lanthanum cerium praseodymium neodymium promethium samarium europium gadolinium terbium dysprosium holmium erbium thulium ytterbium lutetium'
      .split(' '),
  ...'hafnium tantalum tungsten rhenium osmium iridium platinum gold mercury thallium lead bismuth polonium astatine radon'
      .split(' '),
  ...'gallium germanium arsenic selenium bromine krypton rubidium strontium yttrium zirconium niobium molybdenum technetium ruthenium rhodium palladium silver cadmium indium tin antimony tellurium iodine xenon'
      .split(' '),
  ...'sodium magnesium aluminium aluminum silicon phosphorus sulfur sulphur chlorine argon potassium calcium scandium titanium vanadium chromium manganese iron cobalt nickel copper zinc'
      .split(' '),
  ...'hydrogen helium lithium beryllium boron carbon nitrogen oxygen fluorine neon'
      .split(' '),
];
