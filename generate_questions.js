const fs = require('fs');
const path = require('path');

// Real Data Pool
// Format: { term: "Term", desc: "Description", category: "Category" }
const termPool = [
    // Life Planning (ライフプランニングと資金計画)
    { term: "公的年金制度", desc: "国民年金（基礎年金）と厚生年金の2階建て構造になっている日本の年金制度。", category: "Life Planning" },
    { term: "国民年金", desc: "日本国内に住所を有する20歳以上60歳未満のすべての人が加入する年金制度。", category: "Life Planning" },
    { term: "厚生年金", desc: "会社員や公務員などが加入し、国民年金に上乗せして給付される年金制度。", category: "Life Planning" },
    { term: "第3号被保険者", desc: "第2号被保険者に扶養されている20歳以上60歳未満の配偶者。", category: "Life Planning" },
    { term: "可処分所得", desc: "年収から税金や社会保険料を差し引いた、自身で自由に使える手取り収入のこと。", category: "Life Planning" },
    { term: "キャッシュフロー表", desc: "現在の収支状況と将来の収支予測を一覧にした表。", category: "Life Planning" },
    { term: "バランスシート", desc: "ある時点における資産・負債・純資産の状況を表にしたもの。", category: "Life Planning" },
    { term: "フラット35", desc: "住宅金融支援機構と民間金融機関が提携して提供する長期固定金利住宅ローン。", category: "Life Planning" },

    // Risk Management (リスク管理)
    { term: "定期保険", desc: "あらかじめ定めた一定期間内に死亡した場合のみ保険金が支払われる掛け捨て型の保険。", category: "Risk Management" },
    { term: "終身保険", desc: "一生涯にわたり保障が続き、解約した場合には解約返戻金が受け取れる保険。", category: "Risk Management" },
    { term: "養老保険", desc: "保険期間中に死亡した場合は死亡保険金、満期時に生存していた場合は満期保険金が受け取れる保険。", category: "Risk Management" },
    { term: "クーリング・オフ制度", desc: "保険契約の申し込み後、一定期間内であれば無条件で契約を撤回・解除できる制度。", category: "Risk Management" },
    { term: "第三分野の保険", desc: "医療保険やがん保険、介護保険など、生命保険（第一分野）と損害保険（第二分野）の中間に位置する保険。", category: "Risk Management" },

    // Financial Asset Management (金融資産運用)
    { term: "単利", desc: "当初の元本に対してのみ利息がつく計算方法。", category: "Financial Asset" },
    { term: "複利", desc: "元本に利息を加えた金額を新たな元本として計算する方法。「利息が利息を生む」効果がある。", category: "Financial Asset" },
    { term: "債券", desc: "国や企業などが資金調達のために発行する借用証書のような有価証券。", category: "Financial Asset" },
    { term: "投資信託", desc: "多くの投資家から集めた資金を運用の専門家が株式や債券などに投資・運用する金融商品。", category: "Financial Asset" },
    { term: "PER (株価収益率)", desc: "株価が1株当たり純利益の何倍かを示す指標。株価 ÷ 1株当たり純利益で算出する。", category: "Financial Asset" },
    { term: "PBR (株価純資産倍率)", desc: "株価が1株当たり純資産の何倍かを示す指標。株価 ÷ 1株当たり純資産で算出する。", category: "Financial Asset" },
    { term: "インサイダー取引", desc: "企業の内部関係者が、未公表の重要事実を知りながらその株式を売買する違法行為。", category: "Financial Asset" },
    { term: "NISA (少額投資非課税制度)", desc: "一定額までの投資から得られる利益が非課税になる制度。", category: "Financial Asset" },

    // Tax Planning (タックスプランニング)
    { term: "所得税", desc: "個人の1年間の所得に対して課される税金。", category: "Tax Planning" },
    { term: "配偶者控除", desc: "納税者に控除対象配偶者がいる場合に、一定金額の所得控除が受けられる制度。", category: "Tax Planning" },
    { term: "医療費控除", desc: "1年間にかかった医療費が一定額を超えた場合、その超過分を所得から控除できる制度。", category: "Tax Planning" },
    { term: "確定申告", desc: "1年間の所得と税額を計算し、税務署に申告・納税する手続き。", category: "Tax Planning" },
    { term: "源泉徴収", desc: "給与や報酬の支払者が、あらかじめ税金を差し引いて支払う仕組み。", category: "Tax Planning" },
    { term: "青色申告", desc: "正規の簿記で記帳するなど一定の要件を満たすことで、税制上の優遇措置を受けられる申告制度。", category: "Tax Planning" },

    // Real Estate (不動産)
    { term: "建ぺい率", desc: "敷地面積に対する建築面積の割合。", category: "Real Estate" },
    { term: "容積率", desc: "敷地面積に対する延べ床面積の割合。", category: "Real Estate" },
    { term: "抵当権", desc: "住宅ローンなどで金を借りる際、返済が滞った場合に備えて土地や建物を担保とする権利。", category: "Real Estate" },
    { term: "重要事項説明", desc: "不動産の売買や賃貸契約の前に、宅地建物取引士が物件や契約内容について説明すること。", category: "Real Estate" },
    { term: "固定資産税", desc: "土地や家屋などの固定資産を所有している人が市町村に納める税金。", category: "Real Estate" },
    { term: "登記簿", desc: "不動産の所有者や権利関係などが記録された公的な帳簿。", category: "Real Estate" },

    // Inheritance / Business Succession (相続・事業承継)
    { term: "法定相続人", desc: "民法で定められた、遺産を相続する権利を持つ人。", category: "Inheritance" },
    { term: "遺留分", desc: "一定の法定相続人に最低限保証された遺産の取り分。", category: "Inheritance" },
    { term: "相続放棄", desc: "被相続人の財産（プラスの財産もマイナスの財産も）を一切受け継がないこと。", category: "Inheritance" },
    { term: "贈与税", desc: "個人から財産をもらったときにかかる税金。", category: "Inheritance" },
    { term: "公正証書遺言", desc: "公証人が遺言者の口述を筆記して作成する、証拠能力の高い遺言書。", category: "Inheritance" },
    { term: "自筆証書遺言", desc: "遺言者が全文を自筆して作成する遺言書。", category: "Inheritance" }
];

const generatedQuestions = [];
const TOTAL_QUESTIONS = 1000;

// Helper to get random items excluding one
function getRandomDistractors(targetTerm, count) {
    const distractors = [];
    const pool = termPool.filter(t => t.term !== targetTerm.term); // Exclude self

    while (distractors.length < count) {
        const d = pool[Math.floor(Math.random() * pool.length)];
        if (!distractors.includes(d)) {
            distractors.push(d);
        }
    }
    return distractors;
}

// Generate Questions
for (let i = 1; i <= TOTAL_QUESTIONS; i++) {
    // 1. Pick a Correct Answer Term
    const correctTerm = termPool[Math.floor(Math.random() * termPool.length)];

    // 2. Pick 3 Distractors
    const distractors = getRandomDistractors(correctTerm, 3);

    // 3. Formulate Question Options
    // Shuffle descriptions
    const optionTerms = [correctTerm, ...distractors];
    // Fisher-Yates Shuffle
    for (let k = optionTerms.length - 1; k > 0; k--) {
        const j = Math.floor(Math.random() * (k + 1));
        [optionTerms[k], optionTerms[j]] = [optionTerms[j], optionTerms[k]];
    }

    const correctIndex = optionTerms.indexOf(correctTerm);

    // Create Question Object
    // We vary the question format slightly to avoid complete monotony
    const qType = Math.random() > 0.5 ? "desc_to_term" : "term_to_desc";

    let qText = "";
    let options = [];

    if (qType === "term_to_desc") {
        qText = `「${correctTerm.term}」の説明として、適切なものはどれか。`;
        options = optionTerms.map(t => t.desc);
    } else {
        qText = `「${correctTerm.desc}」を指す用語として、適切なものはどれか。`;
        options = optionTerms.map(t => t.term);
    }

    let explanation = "";
    if (qType === "term_to_desc") {
        explanation = `正解は「${correctTerm.desc}」です。\n\nこれは「${correctTerm.term}」の説明です。\n\n他の選択肢の用語と説明:\n${distractors.map(d => "・" + d.term + ": " + d.desc).join("\n")}`;
    } else {
        explanation = `正解は「${correctTerm.term}」です。\n\n${correctTerm.desc}\n\n他の選択肢:\n${distractors.map(d => "・" + d.term + ": " + d.desc).join("\n")}`;
    }

    generatedQuestions.push({
        "id": i,
        "question": qText,
        "options": options,
        "correctIndex": correctIndex,
        "explanation": explanation
    });
}

// Save to file
const outputPath = path.join(__dirname, 'assets', 'questions.json');
fs.writeFileSync(outputPath, JSON.stringify(generatedQuestions, null, 2), 'utf8');

console.log(`Successfully generated ${TOTAL_QUESTIONS} high-quality questions to ${outputPath}`);
