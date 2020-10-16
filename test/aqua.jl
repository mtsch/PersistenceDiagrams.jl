using PersistenceDiagrams
using Aqua

Aqua.test_all(
    PersistenceDiagrams;
    ambiguities=(;exclude=[in]), # from MLJModelInterface
)
